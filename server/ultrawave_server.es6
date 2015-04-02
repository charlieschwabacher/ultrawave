const WSServer = require('./ws_server')
const MapSet = require('../scripts/util/map_set')


const log = (message) => {
  if (UltrawaveServer.log) console.log(message)
}


class UltrawaveServer {

  constructor(port) {
    log(`starting ultrawave server on port ${port}`)

    this.wss = new WSServer({port: port})

    // map room names to sets of peer ids
    this.rooms = new MapSet

    // map peer ids to sets of room names
    this.memberships = new MapSet


    this.wss.on('open', (id) => {
      log(`opened connection to ${id}`)
      this.wss.send(id, 'start', id)
    })

    this.wss.on('close', (id) => {
      log(`closed connection to ${id}`)

      const memberships = this.memberships.get(id)
      if (memberships != null) {
        memberships.forEach((room) => {
          this.rooms.delete(room, id)
        })
      }

      this.memberships.delete(id)
    })


    this.wss.on('create', (id, room) => {
      if (this.rooms.has(room)) {
        log(`client ${id} failed to create ${room}`)
        this.wss.send(id, 'create failed', room)
      } else {
        log(`client ${id} created ${room}`)
        this.memberships.add(id, room)
        this.rooms.add(room, id)
        this.wss.send(id, 'create', room)
      }
    })

    this.wss.on('join', (id, room) => {
      const peers = this.rooms.get(room)
      if (peers != null) {
        log(`client ${id} joined ${room}`)
        peers.forEach((peer) => {
          log(`requsting offer from ${peer} in ${room}`)
          this.wss.send(peer, 'request offer', {room: room, from: id})
        })
        this.memberships.add(id, room)
        this.rooms.add(room, id)
        this.wss.send(id, 'join', room)
      } else {
        log(`client ${id} failed to join ${room}`)
        this.wss.send(id, 'join failed', room)
      }
    })

    this.wss.on('leave', (id, room) => {
      log(`client ${id} left ${room}`)

      this.memberships.delete(id, room)
      this.rooms.delete(room, id)
    })


    this.wss.on('offer', (id, {sdp, room, to}) => {
      log(`client ${id} sent offer to ${to} in ${room}`)
      this.wss.send(to, 'offer', {
        sdp: sdp,
        room: room,
        from: id
      })
    })

    this.wss.on('answer', (id, {sdp, room, to}) => {
      log(`client ${id} sent answer to ${to} in ${room}`)
      this.wss.send(to, 'answer', {
        sdp: sdp,
        room: room,
        from: id
      })
    })

    this.wss.on('candidate', (id, {candidate, room, to}) => {
      log(`client ${id} sent ice candidate to ${to} in ${room}`)
      this.wss.send(to, 'candidate', {
        candidate: candidate,
        room: room,
        from:
      id})
    })
  }


  stop() {
    log('stopping ultrawave server')
    this.wss.close()
  }

}

UltrawaveServer.log = true

module.exports = UltrawaveServer

