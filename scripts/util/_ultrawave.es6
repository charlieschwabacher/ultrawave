//default event types are 'open', 'close', 'join', 'leave', and 'peer'

const WS = require('./ws')
const MapSet = require('./map_set')
const MapMap = require('./map_map')


const RTCPeerConnection = (
  window.RTCPeerConnection or
  window.webkitRTCPeerConnection or
  window.mozRTCPeerConnection
)
const RTCSessionDescription = (
  window.RTCSessionDescription or
  window.mozRTCSessionDescription
)
const RTCIceCandidate = (
  window.RTCIceCandidate or
  window.mozRTCIceCandidate
)



const log = (message) => {
  // console.log message
}


module.exports = class Ultrawave {

  configuration: {
    iceServers: [{url: 'stun:stun.l.google.com:19302'}]
  }

  // use symbols for event types to prevent the possibility that they could
  // clash with message types sent by peers
  events: {
    open: Symbol(),
    close: Symbol(),
    start: Symbol(),
    join: Symbol(),
    peer: Symbol()
  }

  constructor(url) {
    this.ws = new WS url
    this.rooms = new Set
    this.connections = new MapMap
    this.channels = new MapMap
    this.handlers = new MapSet
    this.open = false
    this.id = null


    const addDataChannel = (room, id, dataChannel) => {
      this.channels.set room, id, dataChannel

      dataChannel.addEventListener 'close', =>
        this.channels.delete room, id

      dataChannel.addEventListener 'message', (e) =>
        [type, payload] = JSON.parse e.data
        this.trigger type, room, id, payload
    }

    const addPeerConnection = (room, id, connection) => {
      this.connections.set room, id, connection

      connection.addEventListener 'signalingstatechange', (e) =>
        this.connections.delete room, id if connection.signalingState is 'closed'
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
      return unless this.rooms.has room

      connection = new RTCPeerConnection this.configuration
      dataChannel = connection.createDataChannel "#{room}:#{from}"

      dataChannel.addEventListener 'open', =>
        log('data channel opened to peer')
        this.trigger this.events.peer, room, from

      connection.addEventListener 'icecandidate', (e) =>
        if e.candidate?
          this.ws.send 'candidate', {room, to: from, candidate: e.candidate}

      connection.createOffer (localDescription) =>
        connection.setLocalDescription localDescription, =>
          this.ws.send 'offer', {room, to: from, sdp: localDescription.sdp}

      addDataChannel room, from, dataChannel
      addPeerConnection room, from, connection
    })


    this.ws.on 'offer', ({room, from, sdp}) =>
      log('recieved offer'
      return unless this.rooms.has room

      connection = new RTCPeerConnection this.configuration

      connection.addEventListener 'datachannel', (e) =>
        log('data channel opened by peer'
        addDataChannel room, from, e.channel
        this.trigger this.events.peer, room, from

      connection.addEventListener 'icecandidate', (e) =>
        if e.candidate?
          this.ws.send 'candidate', {room, to: from, candidate: e.candidate}

      remoteDescription = new RTCSessionDescription {sdp, type: 'offer'}
      connection.setRemoteDescription remoteDescription, =>
        connection.createAnswer (localDescription) =>
          connection.setLocalDescription localDescription, =>
            this.ws.send 'answer', {room, to: from, sdp: localDescription.sdp}

      addPeerConnection room, from, connection


    this.ws.on 'answer', ({room, from, sdp}) =>
      log('recieved answer'
      return unless connection = this.connections.get room, from
      remoteDescription = new RTCSessionDescription {sdp, type: 'answer'}
      connection.setRemoteDescription remoteDescription


    this.ws.on 'candidate', ({room, from, candidate}) =>
      log('recieved ice candidate'
      return unless connection = this.connections.get room, from
      candidate = new RTCIceCandidate candidate
      connection.addIceCandidate candidate

  }

  attemptJoin = (action, room, success, failure) ->
    return if this.rooms.has room

    this.ws.send action, room

    onSuccess = (subjectRoom) =>
      return unless subjectRoom is room
      this.ws.off action, onSuccess
      this.ws.off "#{action} failed", onFailure
      this.rooms.add room
      this.trigger this.events.join, room
      success()

    onFailure = (subjectRoom) =>
      return unless subjectRoom is room
      this.ws.off action, onSuccess
      this.ws.off "#{action} failed", onFailure
      failure()

    this.ws.on action, onSuccess
    this.ws.on "#{action} failed", onFailure


  create: (room) ->
    new Promise (resolve, reject) =>
      attemptJoin.apply this, ['create', room, resolve, reject]


  join: (room) ->
    new Promise (resolve, reject) =>
      attemptJoin.apply this, ['join', room, resolve, reject]


  joinOrCreate: (room) ->
    new Promise (resolve) =>
      create = => this.create(room).then(resolve).catch join
      do join = => this.join(room).then(resolve).catch create


  leave: (room) ->
    return unless this.rooms.has room

    this.ws.send 'leave', room

    this.rooms.delete room
    this.connections.get(room)?.forEach (connection) -> connection.close()
    this.connections.delete room
    this.channels.delete room

    this.trigger this.events.leave, room


  on: (type, callback) ->
    this.handlers.add type, callback


  off: (type, callback) ->
    if callback?
      this.handlers.delete type, callback
    else
      this.handlers.delete type


  trigger: (type, args...) ->
    this.handlers.get(type)?.forEach (handler) -> handler.apply null, args


  send: (room, type, payload) ->
    message = JSON.stringify [type, payload]
    this.channels.get(room)?.forEach (channel) -> channel.send message


  close: ->
    this.ws.close()
    this.rooms.forEach (room) =>
      this.connections.get(room)?.forEach (connection) ->
        connection.close()

}


