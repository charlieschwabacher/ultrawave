const deepFreeze = require('./deep_freeze')
const deepMerge = require('./deep_merge')
const CursorCache = require('./cursor_cache')

module.exports = {

  Cursor: class Cursor {},

  create: function(inputData, onChange) {
    const cache = new CursorCache(() => data)
    let data = deepFreeze(inputData)
    let pending = false
    let changes = []

    const update = (newData) => {
      data = newData
      if (!pending) {
        pending = true
        setTimeout(() => {
          pending = false
          onChange(new Cursor, changes)
          changes = []
        })
      }
      return newData
    }

    const modifyAt = (fullPath, modifier) => {
      const newData = Array.isArray(data) ? [] : {}
      let target = newData

      for (let k in data) target[k] = data[k]

      for (let key of fullPath.slice(0, -1)) {
        let updated = Array.isArray(target[key]) ? [] : {}
        for (let k in data) updated[k] = target[k]
        target[key] = updated
        Object.freeze(target)
        target = updated
      }

      const key = fullPath.slice(-1)[0]
      const result = modifier(target, key)
      Object.freeze(target)

      update(newData)

      return result
    }

    const recordChange = (method, ...args) => {
      changes.push([method, args])
    }


    class Cursor extends module.exports.Cursor {
      constructor(path = []) {
        this.path = path
      }

      cursor(path = []) {
        const fullPath = this.path.concat(path)
        const cached = cache.get(fullPath)
        if (cached != null) {
          return cached
        }
        const cursor = new Cursor(fullPath)
        cache.store(cursor)
        return cursor
      }

      get(path = []) {
        let target = data
        for (let key of this.path.concat(path)) {
          target = target[key]
          if (target == null) return undefined
        }
        return target
      }

      set(path, value) {
        if (arguments.length === 1) {
          value = path
          path = []
        }
        const fullPath = this.path.concat(path)

        recordChange('set', fullPath, value)

        if (fullPath.length > 0) {
          cache.clearPath(fullPath)
          modifyAt(fullPath, (target, key) => {
            target[key] = deepFreeze(value)
          })
        } else {
          cache.reset()
          update(value)
        }
        return value
      }

      delete(path = []) {
        const fullPath = this.path.concat(path)

        recordChange('delete', fullPath)

        if (fullPath.length > 0) {
          cache.clearPath(fullPath)
          modifyAt(fullPath, (target, key) => {
            delete target[key]
          })
        } else {
          cache.reset()
          update(undefined)
        }
        return true
      }

      merge(newData) {
        recordChange('merge', this.path, newData)

        cache.clearObject(this.path, newData)
        if (this.path.length > 0) {
          return modifyAt(this.path, (target, key) => {
            target[key] = deepMerge(target[key], deepFreeze(newData))
          })
        } else {
          return update(deepMerge(data, deepFreeze(newData)))
        }
      }

      splice(path, start, deleteCount, ...elements) {
        const fullPath = this.path.concat(path)

        recordChange('splice', fullPath, start, deleteCount, elements)

        cache.spliceArray(fullPath, start, deleteCount, elements.length)

        return modifyAt(fullPath, (target, key) => {
          const arr = target[key]
          if (!Array.isArray(arr)) throw new Error('can\'t splice non array')
          const updated = arr.slice(0)
          const result = updated.splice(start, deleteCount, ...elements)
          target[key] = deepFreeze(updated)
          return result
        })
      }

      push(path, value) {
        return this.splice(path, Infinity, 0, value)
      }

      pop(path) {
        return this.splice(path, -1, 1)[0]
      }

      unshift(path, value) {
        return this.splice(path, 0, 0, value)
      }

      shift(path) {
        return this.splice(path, 0, 1)[0]
      }

      bind(path, pre) {
        return (v) => {
          this.set(path, pre ? pre(v) : v)
        }
      }

      has(path) {
        return this.get(path) != null
      }

    }

    // perform callback one time to start
    onChange(new Cursor)

    // return a 'handle' to the cursor instance
    return {
      data: () => data,
      cache: () => cache,
      pending: () => pending,
      changes: () => changes
    }

  }

}
