// this is used to cache cursors so that two cursors to the same object will be
// referrentially equal.


const cursorSymbol = Symbol()


// define some functions to perform operations on either an Array or Map object

function get(target, key) {
  if (target instanceof Map)
    return target.get(key)
  else
    return target[key]
}

function set(target, key, value) {
  if (target instanceof Map)
    target.set(key, value)
  else
    target[key] = value

  return value
}

function del(target, key) {
  if (target instanceof Map)
    target.delete(key)
  else
    target[key] = undefined

  return true
}

function empty(target) {
  if (target instanceof Map)
    return target.size === 0
  else
    return target.length === 0 && target[cursorSymbol] == null
}


// recursively clear changes along a path, pruning nodes as stack unwinds
// return the last node along the path

function clearPath (node, key, parent, path) {
  if (node == null) return

  let result
  del(node, cursorSymbol)

  if (path.length > 0) {
    const nextKey = path[0]
    const nextNode = get(node, nextKey)
    result = clearPath(nextNode, nextKey, node, path.slice(1))
  } else {
    result = node
  }

  if (parent != null && empty(node)) {
    del(parent, key)
  }

  return result
}

// recursively clear all paths on an object

function clearObject(node, changes) {
  del(node, cursorSymbol)
  for (let k in changes) {
    let next = get(node, k)
    if (next != null) {
      clearObject(next, changes[k])
      if (empty(next)) del(node, k)
    }
  }
}

// recursively count nodes in the cache tree

function size(node) {
  if (node == null) return 0

  if (node instanceof Map) {
    let result = 0
    for (let [key, value] of node) {
      if (key !== cursorSymbol) {
        result += size(value)
      }
    }
    return result + node.size + (node.has(cursorSymbol) ? -1 : 0)
  } else {
    return node.reduce((memo, child) => {
      return child != null ? memo + 1 + size(child) : memo
    }, 0)
  }
}




// the cursor cache class

module.exports = class CursorCache {

  constructor(data) {
    this.data = data
    this.root = new Map
  }

  reset() {
    this.root = new Map
  }

  get(path) {
    let target = this.root
    for (let key of path) {
      target = get(target, key)
      if (target == null) return undefined
    }
    return get(target, cursorSymbol)
  }

  store(cursor) {
    let target = this.root
    let dataTarget = this.data()
    for (let key of cursor.path) {
      dataTarget = (dataTarget == null) ? null : dataTarget[key]
      let next = get(target, key)
      if (next == null) {
        next = Array.isArray(dataTarget) ? [] : new Map
        set(target, key, next)
      }
      target = next
    }
    set(target, cursorSymbol, cursor)
  }

  clearPath(path) {
    return clearPath(this.root, null, null, path)
  }

  clearObject(path, obj) {
    const target = this.clearPath(path)
    if (target == null) return

    clearObject(target, obj)
  }

  spliceArray(path, start, deleteCount, addCount) {
    const target = this.clearPath(path)
    if (target == null) return

    if (!Array.isArray(target)) {
      throw new Error('CursorCache attempted spliceArray on non array')
    }

    target.splice(start, deleteCount, ...(new Array(addCount)))
  }

  size() {
    return size(this.root)
  }

}
