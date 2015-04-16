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
// PeerGroup class

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


class PeerGroup {

  constructor(url) {
    this.ws = new WS(url)
    this.groups = new Set
    this.connections = new MapMap
    this.channels = new MapMap
    this.handlers = new MapSet
    this.open = false
    this.id = null

    const addDataChannel = (group, id, dataChannel) => {
      this.channels.set(group, id, dataChannel)

      dataChannel.addEventListener('close', () =>
        this.channels.delete(group, id)
      )

      dataChannel.addEventListener('message', (e) => {
        let [type, payload] = JSON.parse(e.data)
        this.trigger(type, group, id, payload)
      })
    }

    const addPeerConnection = (group, id, connection) => {
      this.connections.set(group, id, connection)

      connection.addEventListener('signalingstatechange', (e) => {
        if (connection.signalingState === 'closed') {
          this.connections.delete(group, id)
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

    this.ready = new Promise((resolve) => {
      this.ws.on('start', (id) => {
        log('ws started')
        resolve(id)
        this.id = id
        this.trigger(this.events.start, this)
      })
    })

    this.ws.on('request offer', ({group, from}) => {
      log('recieved request for offer')
      if (!this.groups.has(group)) return

      const connection = new RTCPeerConnection(this.configuration)
      const dataChannel = connection.createDataChannel("#{group}:#{from}")

      dataChannel.addEventListener('open', () => {
        log('data channel opened to peer')
        this.trigger(this.events.peer, group, from)
      })

      connection.addEventListener('icecandidate', (e) => {
        if (e.candidate != null) {
          this.ws.send('candidate', {
            group: group,
            to: from,
            candidate: e.candidate
          })
        }
      })

      connection.createOffer((localDescription) => {
        connection.setLocalDescription(localDescription, () => {
          this.ws.send('offer', {
            group: group,
            to: from,
            sdp: localDescription.sdp
          })
        })
      })

      addDataChannel(group, from, dataChannel)
      addPeerConnection(group, from, connection)
    })


    this.ws.on('offer', ({group, from, sdp}) => {
      log('recieved offer')
      if (!this.groups.has(group)) return

      const connection = new RTCPeerConnection(this.configuration)

      connection.addEventListener('datachannel', (e) => {
        log('data channel opened by peer')
        addDataChannel(group, from, e.channel)
        this.trigger(this.events.peer, group, from)
      })

      connection.addEventListener('icecandidate', (e) => {
        if (e.candidate != null) {
          this.ws.send('candidate', {
            group: group,
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
              group: group,
              to: from,
              sdp: localDescription.sdp
            })
          })
        })
      })

      addPeerConnection(group, from, connection)
    })

    this.ws.on('answer', ({group, from, sdp}) => {
      log('recieved answer')
      const connection = this.connections.get(group, from)

      if (connection != null) {
        const remoteDescription = new RTCSessionDescription({
          sdp: sdp,
          type: 'answer'
        })
        connection.setRemoteDescription(remoteDescription)
      }
    })

    this.ws.on('candidate', ({group, from, candidate}) => {
      log('recieved ice candidate')
      const connection = this.connections.get(group, from)

      if (connection != null) {
        const candidate = new RTCIceCandidate(candidate)
        connection.addIceCandidate(candidate)
      }
    })
  }



  attemptAction(action, group, success, failure) {
    if (this.groups.has(group)) return

    const actionFailure = `${action} failed`

    const onSuccess = (subjectGroup) => {
      if (subjectGroup !== group) return
      this.ws.off(action, onSuccess)
      this.ws.off(actionFailure, onFailure)
      this.groups.add(group)
      this.trigger(this.events.join, group)
      success()
    }

    const onFailure = (subjectGroup) => {
      if (subjectGroup !== group) return
      this.ws.off(action, onSuccess)
      this.ws.off(actionFailure, onFailure)
      failure()
    }

    this.ws.on(action, onSuccess)
    this.ws.on(actionFailure, onFailure)
    this.ws.send(action, group)
  }


  create(group) {
    return new Promise((resolve, reject) => {
      this.attemptAction('create', group, resolve, reject)
    })
  }


  join(group) {
    return new Promise((resolve, reject) => {
      this.attemptAction('join', group, resolve, reject)
    })
  }


  joinOrCreate(group) {
    return new Promise((resolve) => {
      const create = () => this.create(group).then(resolve).catch(join)
      const join = () => this.join(group).then(resolve).catch(create)
      join()
    })
  }


  peers(group) {
    return new Set(this.connections.get(group).keys())
  }


  reestablishConnection(group, id) {

  }


  leave(group) {
    if (!this.groups.has(group)) return

    this.ws.send('leave', group)

    this.groups.delete(group)

    const connections = this.connections.get(group)
    if (connections != null) {
      connections.forEach((connection) => connection.close())
    }

    this.connections.delete(group)
    this.channels.delete(group)

    this.trigger(this.events.leave, group)
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
      handlers.forEach((handler) => {
        handler.apply(null, args)
      })
    }
  }


  send(group, type, payload) {
    const channels = this.channels.get(group)
    if (channels != null) {
      const message = JSON.stringify([type, payload])
      channels.forEach((channel) => channel.send(message))
    }
  }


  sendTo(group, id, type, payload) {
    const channel = this.channels.get(group, id)
    if (channel != null) {
      channel.send(JSON.stringify([type, payload]))
    }
  }


  close() {
    this.ws.close()
    this.groups.forEach((group) => {
      const connections = this.connections.get(group)
      if (connections != null) {
        connections.forEach((connection) => connection.close())
      }
    })
  }

}

PeerGroup.prototype.events = events
PeerGroup.prototype.configuration = configuration

module.exports = PeerGroup

