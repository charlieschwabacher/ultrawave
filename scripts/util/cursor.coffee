deepFreeze = require './deep_freeze'
deepMerge = require './deep_merge'
CursorCache = require './cursor_cache'


module.exports =

  # make a cursor superclass accessible for type checking
  Cursor: (class Cursor)

  create: (inputData, onChange) ->

    # this is the master reference to data, any change will replace this object
    data = deepFreeze inputData

    cache = new CursorCache
    pending = false
    clock = 0


    changes = []


    update = (newData) ->
      data = newData
      unless pending
        pending = true
        setTimeout ->
          pending = false
          onChange new Cursor



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
        changes.push [clock, method, args]

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
          @modifyAt fullPath, (target, key) ->
            target[key] = deepFreeze value
            cache.clearPath fullPath
        else
          update value

        value

      delete: (path) ->
        fullPath = @path.concat path
        @recordChange 'delete', [fullPath]

        if fullPath.length > 0
          @modifyAt fullPath, (target, key) ->
            delete target[key]
            cache.clearPath fullPath
        else
          update undefined

        true

      push: (path, value) ->
        fullPath = @path.concat path
        @recordChange 'push', [fullPath, value]

        @modifyAt fullPath, (target, key) ->
          arr = target[key]
          throw new Error 'push called on non array' unless Array.isArray arr
          updated = arr.slice 0
          updated.push value
          target[key] = deepFreeze updated

          cache.clearPath fullPath

          value

      pop: (path) ->
        fullPath = @path.concat path
        @recordChange 'pop', [fullPath]

        @modifyAt fullPath, (target, key) ->
          arr = target[key]
          throw new Error 'pop called on non array' unless Array.isArray arr
          target[key] = deepFreeze arr.slice 0, -1

          cache.clearPath fullPath

          arr[arr.length - 1]

      unshift: (path, value) ->
        fullPath = @path.concat path
        @recordChange 'unshift', [fullPath, value]

        @modifyAt fullPath, (target, key) ->
          arr = target[key]
          throw new Error 'unshift called on non array' unless Array.isArray arr
          updated = arr.slice 0
          updated.unshift value
          target[key] = deepFreeze updated

          cache.clearArray fullPath, 0

          value

      shift: (path) ->
        fullPath = @path.concat path
        @recordChange 'shift', [fullPath]

        @modifyAt fullPath, (target, key) ->
          arr = target[key]
          throw new Error 'pop called on non array' unless Array.isArray arr
          target[key] = deepFreeze arr.slice 1

          cache.clearArray fullPath, 0

          arr[0]

      splice: (path, start, deleteCount, elements...) ->
        fullPath = @path.concat path
        @recordChange 'splice', [fullPath, start, deleteCount, elements]

        @modifyAt fullPath, (target, key) ->
          arr = target[key]
          throw new Error 'slice called on non array' unless Array.isArray arr
          updated = arr.slice 0
          result = updated.splice start, deleteCount, elements...
          target[key] = deepFreeze updated

          count = if deleteCount is elements.length then elements.length else undefined
          cache.clearArray fullPath, start, count

          result

      merge: (newData) ->
        cache.clearObject @path, newData
        @set [], deepMerge @get(), deepFreeze newData

      bind: (path, pre) ->
        (v) => @set path, if pre then pre v else v

      has: (path) ->
        @get(path)?



    # perform callback one time to start
    onChange new Cursor


