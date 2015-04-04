const Ultrawave = require('./ultrawave')
const MapMap = require('./map_map')
const MapArray = require('./map_array')
const Cursor = require('./cursor')


module.exports = class Wormhole {

  constructor(url) {
    this.ultrawave = new Ultrawave(url)
    this.handles = new Map
    this.timeouts = new MapMap
    this.changes = new MapArray


    // respond to requests from peers

    this.ultrawave.on('request document', (room, id) => {
      const data = this.handles.get(room).data()
      const changes = this.changes.get(room)
      this.ultrawave.sendTo(room, id, 'document', {clock: clock, data: data})
    })

    this.ultrawave.on('request changes', (room, id, latest) => {
      for (let i = changes.length - 1; i >= 0; i -= 1) {
        const [clock, method, args] = changes[i]
        if (!clock.laterThan(latest)) return
        this.ultrawave.sendTo(room, id, method, args)
      }
    })

    this.ultrawave.on('request sync', (room, id, {author, ticks}) => {
      const remaining = new Set(ticks)
      for (let i = changes.length - 1; i >= 0; i -= 1) {
        let [clock, method, args] = changes[i]
        if (clock.id === author && remaining.has(clock[author])) {
          this.ultrawave.sendTo(room, id)
          remaining.delete(clock[author])
        }
      }
    })


    // apply changes from peers

    const methods = ['set', 'delete', 'merge', 'splice']
    methods.forEach((method) => {
      this.ultrawave.on(method, (room, id, args) => {
        const cursor = this.handles.get(room)
      })
    })
  }



  create: function(room, initialData, cb) {
    return new Promise((resolve, reject) => {
      this.ultrawave.create(room).then(() => {
        const handle = Cursor.create(initialData, cb)
        this.handles.set(room, handle)
        resolve(handle)
      }).catch(reject)
    })
  },


  join: function(room, cb) {
    const events = this.ultrawave.events

    return new Promise((resolve, reject) => {
      this.ultrawave.join(room).then(() => {

        const onPeer = (subjectRoom, id) => {
          if (subjectRoom !== room) return
          this.ultrawave.off(events.peer, onPeer)
          this.ultrawave.sendTo(room, id, 'request document')
        }
        this.ultrawave.on(events.peer, onPeer)

        const onDocument = (subjectRoom, id, data) => {
          this.ultrawave.off(events.document, onPeer)
          const handle = Cursor.create(data, cb)
          this.handles.set(room, handle)
          resolve(handle)
        }
        this.ultrawave.on('document', onDocument)

      }).catch(reject)
    })
  }

}
