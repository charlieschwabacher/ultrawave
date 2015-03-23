deepFreeze = require './deep_freeze'
deepMerge = require './deep_merge'
CursorCache = require './cursor_cache'


module.exports =

  # make a cursor superclass accessible for type checking
  Cursor: (class Cursor)

  create: (inputData, onChange) ->

    # this is the master reference to data, any change will replace this object
    data = deepFreeze inputData
    cache = new CursorCache -> data
    pending = false

    # clock = 0
    # changes = []


    update = (newData) ->
      data = newData
      unless pending
        pending = true
        setTimeout ->
          pending = false
          onChange new Cursor
      newData


    # create local cursor class w/ access to mutable reference to data
    class Cursor extends module.exports.Cursor

      constructor: (@path = []) ->

      cursor: (path = []) ->
        fullPath = @path.concat path

        return cached if (cached = cache.get fullPath)?

        cursor = new Cursor fullPath
        cache.store cursor
        cursor

      get: (path = []) ->
        target = data
        for key in @path.concat path
          target = target[key]
          return undefined unless target?
        target

      recordChange: (method, args) ->
        # changes.push [clock, method, args]

      modifyAt: (fullPath, modifier) ->
        newData = target = if Array.isArray data then [] else {}
        target[k] = v for k, v of data

        for key in fullPath.slice 0, -1
          updated = if Array.isArray target[key] then [] else {}
          updated[k] = v for k, v of target[key]
          target[key] = updated
          Object.freeze target
          target = target[key]

        key = fullPath.slice(-1)[0]
        result = modifier target, key
        Object.freeze target

        update newData

        result

      set: (path, value) ->
        if arguments.length is 1
          value = path
          path = []

        fullPath = @path.concat path
        @recordChange 'set', [fullPath, value]

        if fullPath.length > 0
          cache.clearPath fullPath
          @modifyAt fullPath, (target, key) ->
            target[key] = deepFreeze value
        else
          cache.reset()
          update value

        value

      delete: (path) ->
        fullPath = @path.concat path
        @recordChange 'delete', [fullPath]

        if fullPath.length > 0
          cache.clearPath fullPath
          @modifyAt fullPath, (target, key) ->
            delete target[key]
        else
          cache.reset()
          update undefined

        true

      merge: (newData) ->
        @recordChange 'merge', [@path, newData]

        if @path.length > 0
          cache.clearObject @path, newData
          @modifyAy @path, (target, key) ->
            target[key] = deepMerge target[key], deepFreeze newData
        else
          cache.clearObject @path, newData
          update deepMerge data, deepFreeze newData

      splice: (path, start, deleteCount, elements...) ->
        fullPath = @path.concat path
        @recordChange 'splice', [fullPath, start, deleteCount, elements]

        cache.spliceArray fullPath, start, deleteCount, elements.length

        @modifyAt fullPath, (target, key) ->
          arr = target[key]
          throw new Error 'slice called on non array' unless Array.isArray arr
          updated = arr.slice 0
          result = updated.splice start, deleteCount, elements...
          target[key] = deepFreeze updated

          result

      push: (path, value) ->
        @splice path, Infinity, 0, value

      pop: (path) ->
        @splice(path, -1, 1)[0]

      unshift: (path, value) ->
        @splice path, 0, 0, value

      shift: (path) ->
        @splice(path, 0, 1)[0]

      bind: (path, pre) ->
        (v) => @set path, if pre then pre v else v

      has: (path) ->
        @get(path)?



    # perform callback one time to start
    onChange new Cursor


    # return a 'handle' to the cursor instance
    cache: -> cache
    data: -> data
    pending: -> pending

