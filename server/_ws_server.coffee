ws = require 'ws'
crypto = require 'crypto'
MapSet = require '../scripts/util/map_set'
WebSocketServer = ws.Server


getId = (cb) -> crypto.randomBytes 8, (ex, buff) ->
  cb buff.toString('base64').replace('/','-').replace('+', '_')

module.exports = class WSServer

  constructor: (opts) ->
    @wss = new WebSocketServer opts
    @handlers = new MapSet
    @sockets = new Map

    @wss.on 'connection', (ws) =>
      getId (id) =>
        @sockets.set id, ws
        @trigger 'open', id

        ws.addEventListener 'close', (e) =>
          @sockets.delete id
          @trigger 'close', id

        ws.addEventListener 'message', (e) =>
          [type, payload] = JSON.parse e.data
          @trigger type, id, payload

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
