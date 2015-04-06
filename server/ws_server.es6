const ws = require('ws')
const crypto = require('crypto')
const MapSet = require('../scripts/data_structures/map_set')
const WebSocketServer = ws.Server


const getId = (cb) => {
  crypto.randomBytes(8, (ex, buff) => {
    cb(buff.toString('base64').replace('/','-').replace('+', '_'))
  })
}

module.exports = class WSServer {

  constructor(opts) {
    this.wss = new WebSocketServer(opts)
    this.handlers = new MapSet
    this.sockets = new Map

    this.wss.on('connection', (ws) => {
      getId((id) => {
        this.sockets.set(id, ws)
        this.trigger('open', id)

        ws.addEventListener('close', (e) => {
          this.sockets.delete(id)
          this.trigger('close', id)
        })

        ws.addEventListener('message', (e) => {
          const [type, payload] = JSON.parse(e.data)
          this.trigger(type, id, payload)
        })
      })
    })
  }

  on(type, callback) {
    this.handlers.add(type, callback)
  }

  off(type, callback) {
    this.handlers.delete(type, callback)
  }

  trigger(type, ...args) {
    const handlers = this.handlers.get(type)
    if (handlers != null) {
      handlers.forEach((handler) => handler.apply(null, args))
    }
  }

  send(id, type, payload) {
    const socket = this.sockets.get(id)
    if (socket != null) {
      socket.send(JSON.stringify([type, payload]))
    }
  }

  close() {
    this.wss.close()
  }

}
