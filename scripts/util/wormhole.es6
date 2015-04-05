const Ultrawave = require('./ultrawave')
const MapMap = require('./map_map')
const Cursor = require('./cursor')


module.exports = class Wormhole {

  constructor(url) {
    this.ultrawave = new Ultrawave(url)
    this.timeouts = new MapMap
    this.handles = new Map
    this.clocks = new Map
    this.changes = new Map // arrays of changes [data, clock, method, args]


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
          if (remaining.size === 0) break
        }
      }
    })


    // apply changes from peers

    const methods = ['set', 'delete', 'merge', 'splice']
    methods.forEach((method) => {
      this.ultrawave.on(method, (room, id, {clock, args}) => {
        // check for and track missing messages

        // update clock
        this.clocks.get(room).update(clock)

        // apply change
        this.applyRemoteChange(room, clock, method, args)
      })
    })
  }


  applyRemoteChange(room, clock, method, args) {
    const changes = this.changes.get(room)
    const handle = this.handles.get(room)

    // if the change is in order, apply it right away and return
    if (clock.laterThan(this.clocks.get(room))) {
      handle[method].apply(null, args)
      changes.push([handle.data(), clock, method, args])
      return
    }

    // find the most recent change earlier than than the incoming change
    let index
    for (index = changes.length - 1; index > 0; index -= 1) {
      if (clock.laterThan(changes[index].clock)) break
    }

    // rewind the data
    handle.set([], changes[index][0])

    // apply the incoming change and splice it in place
    handle[method].apply(null, args)
    changes.splice(index + 1, 0, [handle.data(), clock, method, args])

    // replay changes after the incoming change
    for (index = index + 2; index < changes.length; index += 1) {
      const [,, method, args] = changes[index]
      handle[method].apply(null, args)
    }
  }


  startCursor(room, initialData, cb) {
    const clock = this.clocks.get(room)

    const changes = []
    this.changes.set(room, changes)

    const handle = Cursor.create(initialData, (root, newChanges) => {
      const data = handle.data()
      for (let change of newChanges) {
        const [method, args] = change

        clock.increment()
        const newClock = clock.clone()

        changes.push([data, newClock, method, args])

        this.ultrawave.send(room, method, {clock: newClock, args: args})
      }
      cb(root, changes)
    })
    this.handles.set(room, handle)

    return handle;
  }


  create(room, initialData, cb) {
    return new Promise((resolve, reject) => {
      this.ultrawave.create(room).then(() => {
        this.clocks(room).set(new VectorClock(this.ultrawave.id))
        resolve(this.startCursor(room, initialData, cb))
      }).catch(reject)
    })
  }


  join(room, cb) {
    const events = this.ultrawave.events

    return new Promise((resolve, reject) => {
      this.ultrawave.join(room).then(() => {

        // if the request for document times out, check for new peers and
        // continue to request (need to write this)

        const onPeer = (subjectRoom, id) => {
          if (subjectRoom !== room) return
          this.ultrawave.off(events.peer, onPeer)
          this.ultrawave.sendTo(room, id, 'request document')
        }

        const onDocument = (subjectRoom, id, {clock, data}) => {
          if (subjectRoom !== room) return
          this.ultrawave.off(events.document, onDocument)
          this.clocks.
          resolve(this.startCursor(room, data, cb))
        }

        this.ultrawave.on(events.peer, onPeer)
        this.ultrawave.on('document', onDocument)

      }).catch(reject)
    })
  }


  leave(room) {
    this.ultrawave.leave(room)
    this.handles.delete(room)
    this.clocks.delete(room)
    this.changes.delete(room)
    for (let timeout of this.timeouts.get(room).values()) clearTimeout(timeout)
    this.timeouts.delete(room)

  }


  close() {
    this.ultrawave.close()
  }


}
