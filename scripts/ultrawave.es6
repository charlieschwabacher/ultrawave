//default event types are 'open', 'close', 'join', 'leave', and 'peer'

const WS = require('./ws')
const MapSet = require('./data_structures/map_set')
const MapMap = require('./data_structures/map_map')


const RTCPeerConnection = (
  window.RTCPeerConnection ||
  window.webkitRTCPeerConnection ||
  window.mozRTCPeerConnection
)
const RTCSessionDescription = (
  window.RTCSessionDescription ||
  window.mozRTCSessionDescription
)
const RTCIceCandidate = (
  window.RTCIceCandidate ||
  window.mozRTCIceCandidate
)


const log = (message) => {
  // console.log message
}



// we will set configuration and events on the prototype after creating the
// Ultrawave class

const configuration = {
  iceServers: [{url: 'stun:stun.l.google.com:19302'}]
}

// use symbols for event types to prevent the possibility that they could
// clash with message types sent by peers
const events = {
  open: Symbol(),
  close: Symbol(),
  start: Symbol(),
  join: Symbol(),
  peer: Symbol()
}


class Ultrawave {

  constructor(url) {
    this.ws = new WS(url)
    this.rooms = new Set
    this.connections = new MapMap
    this.channels = new MapMap
    this.handlers = new MapSet
    this.open = false
    this.id = null

    const addDataChannel = (room, id, dataChannel) => {
      this.channels.set(room, id, dataChannel)

      dataChannel.addEventListener('close', () =>
        this.channels.delete(room, id)
      )

      dataChannel.addEventListener('message', (e) => {
        let [type, payload] = JSON.parse(e.data)
        this.trigger(type, room, id, payload)
      })
    }

    const addPeerConnection = (room, id, connection) => {
      this.connections.set(room, id, connection)

      connection.addEventListener('signalingstatechange', (e) => {
        if (connection.signalingState === 'closed') {
          this.connections.delete(room, id)
        }
      })
    }


    this.ws.on('open', () => {
      log('ws opened')
      this.open = true
      this.trigger(this.events.open, this)
    })

    this.ws.on('close', () => {
      log('ws closed')
      this.open = false
      this.trigger(this.events.close, this)
    })

    this.ws.on('start', (id) => {
      log('ws started')
      this.id = id
      this.trigger(this.events.start, this)
    })

    this.ws.on('request offer', ({room, from}) => {
      log('recieved request for offer')
      if (!this.rooms.has(room)) return

      const connection = new RTCPeerConnection(this.configuration)
      const dataChannel = connection.createDataChannel("#{room}:#{from}")

      dataChannel.addEventListener('open', () => {
        log('data channel opened to peer')
        this.trigger(this.events.peer, room, from)
      })

      connection.addEventListener('icecandidate', (e) => {
        if (e.candidate != null) {
          this.ws.send('candidate', {
            room: room,
            to: from,
            candidate: e.candidate
          })
        }
      })

      connection.createOffer((localDescription) => {
        connection.setLocalDescription(localDescription, () => {
          this.ws.send('offer', {
            room: room,
            to: from,
            sdp: localDescription.sdp
          })
        })
      })

      addDataChannel(room, from, dataChannel)
      addPeerConnection(room, from, connection)
    })


    this.ws.on('offer', ({room, from, sdp}) => {
      log('recieved offer')
      if (!this.rooms.has(room)) return

      const connection = new RTCPeerConnection(this.configuration)

      connection.addEventListener('datachannel', (e) => {
        log('data channel opened by peer')
        addDataChannel(room, from, e.channel)
        this.trigger(this.events.peer, room, from)
      })

      connection.addEventListener('icecandidate', (e) => {
        if (e.candidate != null) {
          this.ws.send('candidate', {
            room: room,
            to: from,
            candidate: e.candidate
          })
        }
      })

      const remoteDescription = new RTCSessionDescription({
        sdp: sdp,
        type: 'offer'
      })
      connection.setRemoteDescription(remoteDescription, () => {
        connection.createAnswer((localDescription) => {
          connection.setLocalDescription(localDescription, () => {
            this.ws.send('answer', {
              room: room,
              to: from,
              sdp: localDescription.sdp
            })
          })
        })
      })

      addPeerConnection(room, from, connection)
    })

    this.ws.on('answer', ({room, from, sdp}) => {
      log('recieved answer')
      const connection = this.connections.get(room, from)

      if (connection != null) {
        const remoteDescription = new RTCSessionDescription({
          sdp: sdp,
          type: 'answer'
        })
        connection.setRemoteDescription(remoteDescription)
      }
    })

    this.ws.on('candidate', ({room, from, candidate}) => {
      log('recieved ice candidate')
      const connection = this.connections.get(room, from)

      if (connection != null) {
        const candidate = new RTCIceCandidate(candidate)
        connection.addIceCandidate(candidate)
      }
    })
  }



  attemptAction(action, room, success, failure) {
    if (this.rooms.has(room)) return

    const actionFailure = `${action} failed`

    const onSuccess = (subjectRoom) => {
      if (subjectRoom !== room) return
      this.ws.off(action, onSuccess)
      this.ws.off(actionFailure, onFailure)
      this.rooms.add(room)
      this.trigger(this.events.join, room)
      success()
    }

    const onFailure = (subjectRoom) => {
      if (subjectRoom !== room) return
      this.ws.off(action, onSuccess)
      this.ws.off(actionFailure, onFailure)
      failure()
    }

    this.ws.on(action, onSuccess)
    this.ws.on(actionFailure, onFailure)
    this.ws.send(action, room)
  }


  create(room) {
    return new Promise((resolve, reject) => {
      this.attemptAction('create', room, resolve, reject)
    })
  }


  join(room) {
    return new Promise((resolve, reject) => {
      this.attemptAction('join', room, resolve, reject)
    })
  }


  joinOrCreate(room) {
    return new Promise((resolve) => {
      const create = () => this.create(room).then(resolve).catch(join)
      const join = () => this.join(room).then(resolve).catch(create)
      join()
    })
  }


  leave(room) {
    if (!this.rooms.has(room)) return

    this.ws.send('leave', room)

    this.rooms.delete(room)

    const connections = this.connections.get(room)
    if (connections != null) {
      connections.forEach((connection) => connection.close())
    }

    this.connections.delete(room)
    this.channels.delete(room)

    this.trigger(this.events.leave, room)
  }


  on(type, callback) {
    this.handlers.add(type, callback)
  }


  off(type, callback) {
    if (arguments.length === 1)
      this.handlers.delete(type)
    else
      this.handlers.delete(type, callback)
  }


  trigger(type, ...args) {
    const handlers = this.handlers.get(type)
    if (handlers != null) {
      handlers.forEach((handler) => handler.apply(null, args))
    }
  }


  send(room, type, payload) {
    const channels = this.channels.get(room)
    if (channels != null) {
      const message = JSON.stringify([type, payload])
      channels.forEach((channel) => channel.send(message))
    }
  }


  sendTo(room, id, type, payload) {
    const channel = this.channels.get(room, id)
    if (channel != null) {
      channel.send(JSON.stringify([type, payload]))
    }
  }


  close() {
    this.ws.close()
    this.rooms.forEach((room) => {
      const connections = this.connections.get(room)
      if (connections != null) {
        connections.forEach((connection) => connection.close())
      }
    })
  }

}

Ultrawave.prototype.events = events
Ultrawave.prototype.configuration = configuration

module.exports = Ultrawave

