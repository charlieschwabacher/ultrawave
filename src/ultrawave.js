const PeerGroup = require('peergroup')
const Subtree = require('subtree')
const MapMapMap = require('./data_structures/map_map_map')
const MapMapSet = require('./data_structures/map_map_set')
const MapArray = require('./data_structures/map_array')
const VectorClock = require('./vector_clock')


const interval = 200


class Ultrawave {

  constructor(url) {
    this.handles = new Map
    this.clocks = new Map
    this.changes = new MapArray // arrays of changes [data, clock, method, args]
    this.timeouts = new MapMapMap
    this.peerGroup = new PeerGroup({url: url})

    // wait for id to be assigned by server before binding to other events

    this.peerGroup.ready.then((id) => {

      this.id = id


      // add peers to clock immediately

      this.peerGroup.on(PeerGroup.events.peer, (group, id) => {
        const clock = this.clocks.get(group)
        if (clock != null) {
          clock.touch(id)
        }
      })


      // respond to requests from peers

      this.peerGroup.on('request document', (group, id) => {
        const data = this.handles.get(group).data()
        const clock = this.clocks.get(group)
        this.peerGroup.sendTo(group, id, 'document', {clock: clock, data: data})
      })


      this.peerGroup.on('request changes', (group, id, latest) => {
        latest = new VectorClock(latest)
        const changes = this.changes.get(group)
        for (let i = changes.length - 1; i >= 0; i -= 1) {
          const [, clock, method, args] = changes[i]
          if (latest.laterThan(clock)) return
          if (clock.id === this.id) {
            this.peerGroup.sendTo(group, id, method, {clock: clock, args: args})
          }
        }
      })


      this.peerGroup.on('request sync', (group, id, {author, tick}) => {
        for (let i = changes.length - 1; i >= 0; i -= 1) {
          let [clock, method, args] = changes[i]
          if (clock.id === author && clock[author] == tick) {
            this.peerGroup.sendTo(group, id, method, {clock: clock, args: args})
            break
          }
        }
      })



      // apply changes from peers

      const methods = ['set', 'delete', 'merge', 'splice']
      methods.forEach((method) => {
        this.peerGroup.on(method, (group, id, {clock, args}) => {
          clock = new VectorClock(clock)
          this._clearTimeoutFor(group, clock)
          this._syncMissingChangesFor(id, group, clock)
          this._applyRemoteChange(group, clock, method, args)
          this._updateClock(group, clock)
        })
      })

    })

  }


  _clearTimeoutFor(group, clock) {
    const author = clock.id
    const tick = clock[author]
    const pendingTimeout = this.timeouts.get(group, author, tick)
    if (pendingTimeout != null) {
      clearTimeout(pendingTimeout)
      this.timeouts.delete(group, author, tick)
    }
  }


  _syncMissingChangesFor(sender, group, clock) {

    // compare clock to the current clock to identify any missing messages

    const author = clock.id

    for (let id in clock) {
      const tick = clock[id]
      const latest = author[id]

      if (tick - (latest || 0) > 1) {
        for (let i = latest + 1; i < tick; i++) {

          const requestSync = () => {
            // if we are still connected to the author of the change, request
            // the change from them directly, otherwise request the change from
            // the sender
            if (this.peerGroup.peers(group).has(author)) {
              const peer = author
            } else {
              const peer = sender
            }

            this.peerGroup.sendTo(group, peer, 'request sync', {
              author: author,
              tick: i
            })

            setSyncTimeout()
          }

          const setSyncTimeout = () => {
            const timeout = setTimeout(requestSync, interval)
            this.timeouts.set(group, author, tick, timeout)
          }

          setSyncTimeout()
        }
      }
    }
  }


  _updateClock(group, clock) {
    this.clocks.get(group).update(clock)
  }


  _applyRemoteChange(group, clock, method, args) {
    const changes = this.changes.get(group)
    const handle = this.handles.get(group)

    // if the change is in order, apply it right away and return
    if (clock.laterThan(this.clocks.get(group))) {
      handle[method].apply(null, args)
      changes.push([handle.data(), clock, method, args])
      return
    }

    // find the most recent change earlier than than the incoming change,
    // unless we find that the incoming change has already been applied, in
    // which case we can return without bothering to apply it again
    let index
    const author = clock.id
    for (index = changes.length - 1; index >= 0; index -= 1) {
      const c = changes[index][1]
      if (c.id === author && clock[author] == c[author]) return
      if (clock.laterThan(c)) break
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


  _startCursor(group, initialData, cb) {
    const clock = this.clocks.get(group)

    const changes = []
    this.changes.map.set(group, changes)

    const handle = Subtree.create(initialData, (root, newChanges) => {
      const data = root.get()
      for (let change of newChanges) {
        const [method, args] = change
        clock.increment()
        const newClock = clock.clone()
        changes.push([data, newClock, method, args])
        this.peerGroup.send(group, method, {clock: newClock, args: args})
      }
      cb(root, changes)
    })
    this.handles.set(group, handle)

    return handle;
  }


  join(group, cb) {
    const events = PeerGroup.events

    return new Promise((resolve, reject) => {
      this.peerGroup.ready.then((id) => {
        this.peerGroup.join(group).then(() => {
          this.clocks.set(group, new VectorClock({id: id}))

          // request the current document state from the first peer we form a
          // connection to, then send 'request changes' to each new peer
          // requesting changes they have authored after that clock.
          const docRequestCandidates = []
          let docRequestTimeout
          let changeRequestCandidates
          let documentClock

          const requestDocumentRetry = () => {
             if (docRequestCandidates.length > 0) {
              const peer = docRequestCandidates.shift()
              this.peerGroup.sendTo(group, peer, 'request document')
            }

            docRequestTimeout = setTimeout(requestDocumentRetry, interval)
          }

          const onPeer = (subjectGroup, id) => {
            if (subjectGroup !== group) return

            if (docRequestTimeout == null) {

              // request the document immediately from the first peer

              this.peerGroup.sendTo(group, id, 'request document')
              docRequestTimeout = setTimeout(requestDocumentRetry, interval)

            } else if (documentClock == null) {

              // if the document has not been received, keep track of peers in
              // case we need to request the document from them

              docRequestCandidates.push(id)

            } else if (changeRequestCandidates.has(id)) {

              // once the document has been recevied, request changes from
              // peers as we connect to them

              this.peerGroup.send(group, id, 'request changes', documentClock)
              changeRequestCandidates.delete(id)

              if (changeRequestCandidates.size === 0) {
                this.peerGroup.off(events.peer, onPeer)
              }
            }
          }

          const onDocument = (subjectGroup, id, {clock, data}) => {
            if (subjectGroup !== group) return
            this.peerGroup.off(events.document, onDocument)
            clearTimeout(docRequestTimeout)

            clock = new VectorClock(clock)
            this._updateClock(group, clock)

            // request changes from all group members
            changeRequestCandidates = new Set(clock.keys())
            changeRequestCandidates.delete(clock.id)
            for (let peer of this.peerGroup.peers(group)) {
              if (changeRequestCandidates.delete(peer)) {
                this.peerGroup.send(group, 'request changes', clock)
              }
            }

            resolve(this._startCursor(group, data, cb))
          }

          this.peerGroup.on(events.peer, onPeer)
          this.peerGroup.on('document', onDocument)

        }).catch(reject)
      })
    })
  }


  create(group, initialData, cb) {
    return new Promise((resolve, reject) => {
      this.peerGroup.ready.then((id) => {
        this.peerGroup.create(group).then(() => {
          this.clocks.set(group, new VectorClock({id: id}))
          resolve(this._startCursor(group, initialData, cb))
        }).catch(reject)
      })
    })
  }


  joinOrCreate(group, initialData, cb) {
    return new Promise((resolve, reject) => {
      let tries = 10
      const attempt = (action) => () => {
        (tries -= 1 > 0) ? action() : reject()
      }

      this.peerGroup.ready.then((id) => {
        const create = attempt(() => {
          return this.create(group, initialData, cb).then(resolve).catch(join)
        })
        const join = attempt(() => {
          return this.join(group, cb).then(resolve).catch(create)
        })
        join()
      })
    })
  }


  leave(group) {
    this.peerGroup.leave(group)
    for (let timeout of this.timeouts.get(group).values()) {
      clearTimeout(timeout)
    }

    this.handles.delete(group)
    this.clocks.delete(group)
    this.changes.delete(group)
    this.timeouts.delete(group)
  }


  close() {
    this.peerGroup.close()
  }

}

// export cursor superclass for type checking

Ultrawave.Cursor = Subtree.Cursor


module.exports = Ultrawave




