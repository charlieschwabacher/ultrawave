module.exports = class MapMap

  constructor: ->
    @map = new Map

  get: (key1, key2) ->
    if arguments.length is 1
      @map.get key1
    else
      @map.get(key1)?.get key2

  set: (key1, key2, value) ->
    map = @map.get key1
    unless map?
      map = new Map
      @map.set key1, map

    map.set key2, value

  delete: (key1, key2) ->
    if arguments.length is 1
      @map.delete key1
    else
      @map.get(key1)?.delete key2

  has: (key1, key2) ->
    if arguments.length is 1
      @map.has key1
    else
      @map.get(key1)?.has key2
