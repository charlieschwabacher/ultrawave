const MapSet = require('./data_structures/map_set')


module.exports = class WS {

  constructor(url) {
    this.ws = new WebSocket(url)
    this.handlers = new MapSet

    this.ws.addEventListener('open', () => this.trigger('open'))
    this.ws.addEventListener('close', () => this.trigger('close'))
    this.ws.addEventListener('message', (e) => {
      const [type, payload] = JSON.parse(e.data)
      this.trigger(type, payload)
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

  send(type, payload) {
    this.ws.send(JSON.stringify([type, payload]))
  }

  close() {
    this.ws.close()
  }

}
