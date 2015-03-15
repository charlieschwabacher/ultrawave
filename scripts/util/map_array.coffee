module.exports = class MapArray

  constructor: ->
    @map = new Map

  get: (key) ->
    @map.get key

  push: (key, value) ->
    arr = @map.get key
    unless arr?
      arr = []
      @map.set key, arr

    arr.push value
