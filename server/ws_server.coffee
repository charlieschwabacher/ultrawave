ws = require 'ws'
MapSet = require '../scripts/util/map_set'
WebSocketServer = ws.Server

module.exports = class WSServer

  constructor: ->
    @wss = new WebSocketServer port: 3002
    @handlers = new MapSet
    @sockets = new Map

    idCounter = 0

    @wss.on 'connection', (ws) =>
      id = idCounter += 1
      @sockets.set id, ws

      @handlers.get('open')?.forEach (handler) -> handler id

      ws.addEventListener 'close', (e) =>
        @sockets.delete id
        @handlers.get('close')?.forEach (handler) -> handler id

      ws.addEventListener 'message', (e) =>
        [type, payload] = JSON.parse e.data
        @handlers.get(type)?.forEach (handler) -> handler id, payload

  on: (type, callback) ->
    @handlers.add type, callback

  off: (type, callback) ->
    @handlers.delete type, callback

  send: (id, type, payload) ->
    @sockets.get(id)?.send JSON.stringify [type, payload]

  close: ->
    @wss.close()
