const Ultrawave = require('./ultrawave')
const Cursor = require('./cursor')
const MapMapMap = require('./data_structures/map_map_map')
const MapMapSet = require('./data_structures/map_map_set')
const MapArray = require('./data_structures/map_array')


const timeoutInterval = 200


module.exports = class Wormhole {

  constructor(url) {
    this.ultrawave = new Ultrawave(url)
    this.handles = new Map
    this.clocks = new Map
    this.changes = new MapArray // arrays of changes [data, clock, method, args]
    this.timeouts = new MapMapMap


    // respond to requests from peers

    this.ultrawave.on('request document', (room, id) => {
      const data = this.handles.get(room).data()
      const changes = this.changes.get(room)
      this.ultrawave.sendTo(room, id, 'document', {clock: clock, data: data})
    })

    this.ultrawave.on('request changes', (room, id, latest) => {
      for (let i = changes.length - 1; i >= 0; i -= 1) {
        const [, clock, method, args] = changes[i]
        if (!clock.laterThan(latest)) return
        this.ultrawave.sendTo(room, id, method, {clock: clock, args: args})
      }
    })

    this.ultrawave.on('request sync', (room, id, {author, tick}) => {
      for (let i = changes.length - 1; i >= 0; i -= 1) {
        let [clock, method, args] = changes[i]
        if (clock.id === author && clock[author == tick)) {
          this.ultrawave.sendTo(room, id, method, {clock: clock, args: args})
          break
        }
      }
    })


    // apply changes from peers

    const methods = ['set', 'delete', 'merge', 'splice']
    methods.forEach((method) => {
      this.ultrawave.on(method, (room, id, {clock, args}) => {
        this._clearTimeoutFor(room, clock)
        this._syncMissingChangesFor(id, room, clock)
        this._updateClock(room, clock)
        this._applyRemoteChange(room, clock, method, args)
      })
    })

  }


  clearTimeoutFor(room, clock) {
    const author = clock.id
    const tick = clock[author]
    const pendingTimeout = this.timeouts.get(room, author, tick)
    if (pendingTimeout != null) {
      clearTimeout(pendingTimeout)
      this.timeouts.delete(room, author, tick)
    }
  }


  syncMissingChangesFor(sender, room, clock) {

    // compare clock to the current clock to identify any missing messages

    for (let id in clock) {
      const tick = clock[id]
      const latest = currentClock[id]

      if (tick - (latest || 0) > 1) {
        for (let i = latest + 1; i < tick; i++) {

          // if we have not received any of these missing changes after
          // timeoutInterval, request them from another peer

          const requestSync = () => {
            const peer = _chooseSyncPeer(sender, room, clock)
            this.ultrawave.sendTo(room, peer, 'request sync', {
              author: clock.id,
              tick: i
            })
            setSyncTimeout()
          }

          const setSyncTimeout = () => {
            const timeout = setTimeout(requestSync, timeoutInterval)
            this.timeouts.set(room, author, tick, timeout)
          }

          setSyncTimeout()
        }
      }
    }
  }


  _chooseSyncPeer(sender, room, clock) {

  }


  _updateClock(room, clock) {
    this.clocks.get(room).update(clock)
  }


  _applyRemoteChange(room, clock, method, args) {
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
        // continue to request
        const connectedPeers = new Set
        const documentRequestedPeers = new Set
        const changesRequestedPeers = new Set
        const changesReceivedPeers = new Set

        let documentRequest

        const requestDocument = (id) => {
          this.ultrawave.sendTo(room, id, 'request document')
          documentRequestedPeers.add(id)
        }

        const requestDocumentRetry = () => {
          documentRequest = setTimeout(requestDocumentRetry, timeoutInterval)
        }

        const onFirstPeer = (subjectRoom, id) => {
          if (subjectRoom !== room) return
          this.ultrawave.off(events.peer, onFirstPeer)
          this.ultrawave.on(events.peer, onSubsequentPeer)
          connectedPeers.add(id)
          requestDocument(id)
          documentRequest = setTimeout(requestDocumentRetry, timeoutInterval)
        }

        const onSubsequentPeer = (subjectRoom, id) => {
          if (subjectRoom !== room) return
          this.connectedPeers.add(id)
        }

        const onDocument = (subjectRoom, id, {clock, data}) => {
          if (subjectRoom !== room) return
          this.ultrawave.off(events.document, onDocument)
          clearTimeout(documentRequest)
          // request changes from all room members
          pendingChanges

          resolve(this.startCursor(room, data, cb))
        }

        this.ultrawave.on(events.peer, onPeer)
        this.ultrawave.on('document', onDocument)

      }).catch(reject)
    })
  }


  leave(room) {
    this.ultrawave.leave(room)
    for (let timeout of this.timeouts.get(room).values()) clearTimeout(timeout)
    this.handles.delete(room)
    this.clocks.delete(room)
    this.changes.delete(room)
    this.timeouts.delete(room)
  }


  close() {
    this.ultrawave.close()
  }


}
