const WSServer = require('./ws_server')
const MapSet = require('../scripts/data_structures/map_set')


const log = (message) => {
  if (GroupServer.log) console.log(message)
}


class GroupServer {

  constructor(port) {
    log(`starting ultrawave server on port ${port}`)

    this.wss = new WSServer({port: port})

    // map group names to sets of peer ids
    this.groups = new MapSet

    // map peer ids to sets of group names
    this.memberships = new MapSet


    this.wss.on('open', (id) => {
      log(`opened connection to ${id}`)
      this.wss.send(id, 'start', id)
    })

    this.wss.on('close', (id) => {
      log(`closed connection to ${id}`)

      const memberships = this.memberships.get(id)
      if (memberships != null) {
        memberships.forEach((group) => {
          this.groups.delete(group, id)
        })
      }

      this.memberships.delete(id)
    })


    this.wss.on('create', (id, group) => {
      if (this.groups.has(group)) {
        log(`client ${id} failed to create ${group}`)
        this.wss.send(id, 'create failed', group)
      } else {
        log(`client ${id} created ${group}`)
        this.memberships.add(id, group)
        this.groups.add(group, id)
        this.wss.send(id, 'create', group)
      }
    })

    this.wss.on('join', (id, group) => {
      const peers = this.groups.get(group)
      if (peers != null) {
        log(`client ${id} joined ${group}`)
        peers.forEach((peer) => {
          log(`requsting offer from ${peer} in ${group}`)
          this.wss.send(peer, 'request offer', {group: group, from: id})
        })
        this.memberships.add(id, group)
        this.groups.add(group, id)
        this.wss.send(id, 'join', group)
      } else {
        log(`client ${id} failed to join ${group}`)
        this.wss.send(id, 'join failed', group)
      }
    })

    this.wss.on('leave', (id, group) => {
      log(`client ${id} left ${group}`)

      this.memberships.delete(id, group)
      this.groups.delete(group, id)
    })


    this.wss.on('offer', (id, {sdp, group, to}) => {
      log(`client ${id} sent offer to ${to} in ${group}`)
      this.wss.send(to, 'offer', {
        sdp: sdp,
        group: group,
        from: id
      })
    })

    this.wss.on('answer', (id, {sdp, group, to}) => {
      log(`client ${id} sent answer to ${to} in ${group}`)
      this.wss.send(to, 'answer', {
        sdp: sdp,
        group: group,
        from: id
      })
    })

    this.wss.on('candidate', (id, {candidate, group, to}) => {
      log(`client ${id} sent ice candidate to ${to} in ${group}`)
      this.wss.send(to, 'candidate', {
        candidate: candidate,
        group: group,
        from:
      id})
    })
  }


  stop() {
    log('stopping ultrawave server')
    this.wss.close()
  }

}

GroupServer.log = true

module.exports = GroupServer

