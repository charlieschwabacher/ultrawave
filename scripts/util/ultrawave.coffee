# default event types are 'open', 'close', 'join', 'leave', and 'peer'

WS = require './ws'
MapSet = require './map_set'
MapMap = require './map_map'


RTCPeerConnection = window.webkitRTCPeerConnection or window.mozRTCPeerConnection
RTCSessionDescription = window.RTCSessionDescription or window.mozRTCSessionDescription
RTCIceCandidate = window.RTCIceCandidate or window.mozRTCIceCandidate


log = (message) -> #console.log message



module.exports = class Ultrawave

  configuration:
    iceServers: [url: 'stun:stun.l.google.com:19302']

  # use symbols for event types to prevent the possibility that they could clash
  # with message types send by peers
  events:
    open: Symbol()
    close: Symbol()
    start: Symbol()
    join: Symbol()
    peer: Symbol()

  constructor: (url) ->
    @ws = new WS url
    @rooms = new Set
    @connections = new MapMap
    @channels = new MapMap
    @handlers = new MapSet
    @open = false
    @id = null


    addDataChannel = (room, id, dataChannel) =>
      @channels.set room, id, dataChannel

      dataChannel.addEventListener 'close', =>
        @channels.delete room, id

      dataChannel.addEventListener 'message', (e) =>
        [type, payload] = JSON.parse e.data
        @trigger type, room, id, payload


    addPeerConnection = (room, id, connection) =>
      @connections.set room, id, connection

      connection.addEventListener 'signalingstatechange', (e) =>
        @connections.delete room, id if connection.signalingState is 'closed'



    @ws.on 'open', =>
      log 'ws opened'
      @open = true
      @trigger @events.open, this


    @ws.on 'close', =>
      log 'ws closed'
      @open = false
      @trigger @events.close, this


    @ws.on 'start', (id) =>
      log 'ws started'
      @id = id
      @trigger @events.start, this


    @ws.on 'request offer', ({room, from}) =>
      log 'recieved request for offer'
      return unless @rooms.has room

      connection = new RTCPeerConnection @configuration
      dataChannel = connection.createDataChannel "#{room}:#{from}"

      dataChannel.addEventListener 'open', =>
        log 'data channel opened to peer'
        @trigger @events.peer, room, from

      connection.addEventListener 'icecandidate', (e) =>
        if e.candidate?
          @ws.send 'candidate', {room, to: from, candidate: e.candidate}

      connection.createOffer (localDescription) =>
        connection.setLocalDescription localDescription, =>
          @ws.send 'offer', {room, to: from, sdp: localDescription.sdp}

      addDataChannel room, from, dataChannel
      addPeerConnection room, from, connection


    @ws.on 'offer', ({room, from, sdp}) =>
      log 'recieved offer'
      return unless @rooms.has room

      connection = new RTCPeerConnection @configuration

      connection.addEventListener 'datachannel', (e) =>
        log 'data channel opened by peer'
        addDataChannel room, from, e.channel
        @trigger @events.peer, room, from

      connection.addEventListener 'icecandidate', (e) =>
        if e.candidate?
          @ws.send 'candidate', {room, to: from, candidate: e.candidate}

      remoteDescription = new RTCSessionDescription {sdp, type: 'offer'}
      connection.setRemoteDescription remoteDescription, =>
        connection.createAnswer (localDescription) =>
          connection.setLocalDescription localDescription, =>
            @ws.send 'answer', {room, to: from, sdp: localDescription.sdp}

      addPeerConnection room, from, connection


    @ws.on 'answer', ({room, from, sdp}) =>
      log 'recieved answer'
      return unless connection = @connections.get room, from
      remoteDescription = new RTCSessionDescription {sdp, type: 'answer'}
      connection.setRemoteDescription remoteDescription


    @ws.on 'candidate', ({room, from, candidate}) =>
      log 'recieved ice candidate'
      return unless connection = @connections.get room, from
      candidate = new RTCIceCandidate candidate
      connection.addIceCandidate candidate


  attemptJoin = (action, room, success, failure) ->
    return if @rooms.has room

    @ws.send action, room

    onSuccess = (subjectRoom) =>
      return unless subjectRoom is room
      @ws.off action, onSuccess
      @ws.off "#{action} failed", onFailure
      @rooms.add room
      @trigger @events.join, room
      success?()

    onFailure = (subjectRoom) =>
      return unless subjectRoom is room
      @ws.off action, onSuccess
      @ws.off "#{action} failed", onFailure
      failure?()

    @ws.on action, onSuccess
    @ws.on "#{action} failed", onFailure


  create: (room, success, failure) ->
    attemptJoin.apply this, ['create', room, success, failure]


  join: (room, success, failure) ->
    attemptJoin.apply this, ['join', room, success, failure]


  joinOrCreate: (room, success) ->
    create = => @create room, success, join
    do join = => @join room, success, create


  leave: (room, success, failure) ->
    return unless @rooms.has room

    @ws.send 'leave', room

    @rooms.delete room
    @connections.get(room)?.forEach (connection) -> connection.close()
    @connections.delete room
    @channels.delete room

    @trigger @events.leave, room


  on: (type, callback) ->
    @handlers.add type, callback


  off: (type, callback) ->
    if callback?
      @handlers.delete type, callback
    else
      @handlers.delete type


  trigger: (type, args...) ->
    @handlers.get(type)?.forEach (handler) -> handler.apply null, args


  send: (room, type, payload) ->
    message = JSON.stringify [type, payload]
    @channels.get(room)?.forEach (channel) -> channel.send message


  close: ->
    @rooms.forEach (room) ->
      @connections.get(room).forEach (connection) ->
        connection.close()



