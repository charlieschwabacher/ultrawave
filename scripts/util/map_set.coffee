module.exports = class MapSet

  constructor: ->
    @map = new Map

  get: (key) ->
    @map.get key

  add: (key, value) ->
    set = @map.get key
    unless set?
      set = new Set
      @map.set key, set

    set.add value

  delete: (key, value) ->
    if value?
      set = @map.get key
      if set?
        set.delete value
        @map.delete key if set.size is 0
    else
      @map.delete key
