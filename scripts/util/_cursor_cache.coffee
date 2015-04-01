# this is used to cache cursors so that two cursors to the same object will be
# referrentially equal.  based on its use in cursor, it gaurantees that two
# cursors to different objects will never be equal, but it sometimes clears
# more of the cache than is necessary.
#
# This can be updated to avoid clearing - it needs to be aware of array splices
# so that all children do not need to be cleared at the end of clearpath.


cursorSymbol = Symbol()


get = (target, key) ->
  if target instanceof Map
    target.get key
  else
    target[key]

set = (target, key, value) ->
  if target instanceof Map
    target.set key, value
  else
    target[key] = value

del = (target, key) ->
  if target instanceof Map
    target.delete key
  else
    target[key] = undefined

empty = (target) ->
  if target instanceof Map
    target.size is 0
  else
    target.length is 0 and not target[cursorSymbol]?


module.exports = class CursorCache


  constructor: (data) ->
    @data = data
    @root = new Map


  reset: ->
    @root = new Map


  get: (path) ->
    target = @root
    for key in path
      target = get target, key
      return undefined unless target?
    get target, cursorSymbol


  store: (cursor) ->
    target = @root
    dataTarget = @data()
    for key in cursor.path
      dataTarget = dataTarget?[key]
      unless (next = get target, key)?
        next = if dataTarget instanceof Array then [] else new Map
        set target, key, next
      target = next
    set target, cursorSymbol, cursor


  # recursively clear changes along a path, pruning nodes as stack unwinds
  # return the last node along the path

  clearPath = (node, key, parent, path) ->
    return unless node?
    del node, cursorSymbol

    if path.length > 0
      nextKey = path[0]
      nextNode = get node, nextKey
      result = clearPath nextNode, nextKey, node, path.slice 1
    else
      result = node

    del parent, key if parent? and empty node

    result

  clearPath: (path) ->
    clearPath @root, null, null, path


  # recursively clear all paths on an object

  clearObject = (node, changes) ->
    del node, cursorSymbol
    for k of changes
      if (next = get node, k)?
        clearObject next, changes[k]
        del node, k if empty next

  clearObject: (path, obj) ->
    target = @clearPath path
    return unless target?

    clearObject target, obj


  # clear certain elements in an array by index, shifting following elements

  spliceArray: (path, start, deleteCount, addCount) ->
    target = @clearPath path
    return unless target?

    unless target instanceof Array
      throw new Error 'CursorCache attempted spliceArray on non array'

    target.splice start, deleteCount, (new Array addCount)...


  # recursively count nodes in the cache tree

  size = (node) ->
    return 0 unless node?

    if node instanceof Map
      node.size +
      (if node.has cursorSymbol then -1 else 0) +
      do ->
        keys = node.keys()
        result = 0
        while ({done, value} = keys.next()) and not done
          if value isnt cursorSymbol
            result += size node.get value
        result
    else
      node.reduce (memo, child) ->
        if child?
        then memo + 1 + size child
        else memo
      , 0

  size: -> size @root

