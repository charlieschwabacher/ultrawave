// this is used to cache cursors so that two cursors to the same object will be
// referrentially equal.


const cursorSymbol = Symbol()


function get(target, key) {
  if target instanceof Map
    target.get key
  else
    target[key]
}

function set(target, key, value) {
  if target instanceof Map
    target.set key, value
  else
    target[key] = value
}

function del(target, key) {
  if target instanceof Map
    target.delete key
  else
    target[key] = undefined
}

function empty(target) {
  if target instanceof Map
    target.size is 0
  else
    target.length is 0 and not target[cursorSymbol]?
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

  result
}

// recursively clear all paths on an object

function clearObject(node, key, parent, changes) {
  for (k in changes) {
    const child = get(node, k)
    if (child != null) {
      del(child, cursorSymbol)
      clearObject(child, node, k, changes[k])

      if (parent != null && empty(child)) {
        del(parent, key)
      }
    }
  }
}

// recursively count nodes in the cache tree

function size(node) {
  if (node == null) return 0

  if (node instanceof Map) {
    let result = 0
    for (let [key, value] of node)
      if (key !== cursorSymbol) {
        result += size(value)
      }
    }
    return result + node.size + node.has(cursorSymbol) ? -1 : 0
  } else {
    node.reduce((memo, child) => {
      (child != null) ? memo + 1 + size(child) : memo
    }, 0)
  }
}






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
    for (key of path) {
      target = get target, key
      if (target == null) return undefined
    }
    return get(target, cursorSymbol)
  }

  store(cursor) {
    let target = this.root, next
    let dataTarget = this.data()
    for (key of cursor.path) {
      dataTarget = dataTarget?[key]
      let next = get(target, key)
      if (next == null) {
        next = (Array.isArray(dataTarget)) ? [] : new Map
        set(target, key, next)
      }
      target = next
    }
    set(target, cursorSymbol, cursor)
  }

  clearPath(path) {
    clearPath(this.root, null, null, path)
  }

  clearObject(path, obj) {
    const target = this.clearPath(path)
    if (target == null) return

    clearObject(target, null, null, obj)
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
