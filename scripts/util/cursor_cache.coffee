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


  # recursively clear changes along a path

  clearPath = (node, key, parent, path) ->
    del node, cursorSymbol
    key = path[0]
    return unless (next = get node, key)?
    clearPath next, key, node, path.slice 1
    del parent, key if empty node

  clearPath: (path) ->
    clearPath @root, null, null, path


  # recursively clear changes made by merge

  clearObject = (node, key, parent, changes) ->
    for k of changes
      if (child = get node, k)?
        del child, cursorSymbol
        clearObject child, node, k, changes[k]
        del parent, key if parent? and empty child

    node

  clearObject: (path, obj) ->
    target = @root
    for key in path
      return unless (target = get target, key)?

    clearObject target, null, null, obj


  # clear certain elements in an array by index, shifting following elements

  spliceArray: (path, start, deleteCount, addCount) ->
    target = @root
    for key in path
      return unless (target = get target, key)?

    unless target instanceof Array
      throw new Error 'CursorCache attempted spliceArray on non array'

    target.splice start, deleteCount, (new Array addCount)...


  # recursively count nodes in the cache tree

  size = (node) ->
    return 0 unless node?

    if node instanceof Map

      node.size +
      (if node.has(cursorSymbol) then 0 else 1) +
      (
        for kv of node.entries()
          console.log kv
          [key, child] = kv
          if key is cursorSymbol
            0
          else
            size child
      ).reduce ((memo, num) -> memo + num), 0
    else
      1 + node.reduce (memo, node) ->
        size node
      , 0

  size: -> 1 + size @root

