# return true if an object has no properites, false otherwise
isEmpty = (o) ->
  for k, v of o
    return false if o.hasOwnProperty k
  true


module.exports = class CursorCache

  constructor: ->
    @root = children: {}

  get: (path) ->
    target = @root
    for key in path
      target = target.children[key]
      return undefined unless target?
    target.cursor

  store: (cursor) ->
    target = @root
    for key in cursor.path
      target.children[key] ||= children: {}
      target = target.children[key]
    target.cursor = cursor

  clearPath: (path) ->
    target = @root
    nodes = []

    # clear cached cursors along path
    for key, i in path
      break unless target.children[key]?
      target = target.children[key]
      nodes.push target
      delete target.cursor

    # prune empty nodes along path starting at leaves
    # for i in [nodes.length - 1 ... 0]
    #   node = nodes[i]
    #   if isEmpty node.children
    #     delete nodes[i - 1].children[path[i]]
    #   else
    #     break

    @root


  clearArray: ->


  # recursively clear changes made by merge

  clearObject = (node, changes) ->
    for k of changes
      if (child = node.children[k])?
        delete child.cursor
        clearObject child, changes[k]
    node

  clearObject: (path, obj) ->
    target = @root
    for key in path
      target = target.children[key]
      return unless target?

    clearObject target, obj

