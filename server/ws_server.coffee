ws = require 'ws'
crypto = require 'crypto'
MapSet = require '../scripts/util/map_set'
WebSocketServer = ws.Server


getId = (cb) -> crypto.randomBytes 16, (ex, buff) -> cb buff.toString 'base64'

module.exports = class WSServer

  constructor: (opts) ->
    @wss = new WebSocketServer opts
    @handlers = new MapSet
    @sockets = new Map

    @wss.on 'connection', (ws) =>
      getId (id) =>
        @sockets.set id, ws
        @trigger id, 'open'

        ws.addEventListener 'close', (e) =>
          @sockets.delete id
          @trigger id, 'close'

        ws.addEventListener 'message', (e) =>
          [type, payload] = JSON.parse e.data
          @trigger id, type, payload

  on: (type, callback) ->
    @handlers.add type, callback

  off: (type, callback) ->
    @handlers.delete type, callback

  trigger: (type, args...) ->
    @handlers.get(type)?.forEach (handler) -> handler.apply null, args

  send: (id, type, payload) ->
    @sockets.get(id)?.send JSON.stringify [type, payload]

  close: ->
    @wss.close()
