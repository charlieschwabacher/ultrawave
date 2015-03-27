MapSet = require './map_set'

module.exports = class WS

  constructor: (url) ->
    @ws = new WebSocket url
    @handlers = new MapSet

    @ws.addEventListener 'open', => @trigger 'open'
    @ws.addEventListener 'close', => @trigger 'close'
    @ws.addEventListener 'message', (e) =>
      [type, payload] = JSON.parse e.data
      @trigger type, payload

  on: (type, callback) ->
    @handlers.add type, callback

  off: (type, callback) ->
    @handlers.delete type, callback

  trigger: (type, args...) ->
    @handlers.get(type)?.forEach (handler) -> handler.apply null, args

  send: (type, payload) ->
    @ws.send JSON.stringify [type, payload]

  close: ->
    @ws.close()
