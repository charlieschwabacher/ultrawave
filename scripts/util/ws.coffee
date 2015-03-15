MapSet = require './map_set'

module.exports = class WS

  constructor: (url) ->
    @ws = new WebSocket url
    @handlers = new MapSet

    @ws.addEventListener 'open', =>
      @handlers.get('open')?.forEach (handler) -> handler()

    @ws.addEventListener 'close', =>
      @handlers.get('close')?.forEach (handler) -> handler()

    @ws.addEventListener 'message', (e) =>
      [type, payload] = JSON.parse e.data
      @handlers.get(type)?.forEach (handler) -> handler payload

  on: (type, callback) ->
    @handlers.add type, callback

  off: (type, callback) ->
    @handlers.delete type, callback

  send: (type, payload) ->
    @ws.send JSON.stringify [type, payload]
