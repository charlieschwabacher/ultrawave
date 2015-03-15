# default event types are 'open', 'close', 'join', 'leave', and 'peer'

WS = require './util/ws'
MapSet = require './util/map_set'
MapMap = require './util/map_map'
RTCPeerConnection = window.webkitRTCPeerConnection or window.mozRTCPeerConnection
RTCSessionDescription = window.RTCSessionDescription or window.mozRTCSessionDescription
RTCIceCandidate = window.RTCIceCandidate or window.mozRTCIceCandidate


log = (message) -> console.log message



module.exports = class Ultrawave

  configuration:
    iceServers: [url: 'stun:stun.l.google.com:19302']


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

      dataChannel.addEventListener 'close', ->
        @channels.delete room, id

      dataChannel.addEventListener 'message', (e) =>
        console.log 'received message from ' + id + ' in ' + room + ': ' + e.data
        [type, payload] = JSON.parse e.data
        @handlers.get(type)?.forEach (handler) -> handler room, id, payload


    addPeerConnection = (room, id, connection) =>
      @connections.set room, id, connection

      connection.addEventListener 'signalingstatechange', (e) ->
        @connections.delete room, id if connection.signalingState is 'closed'



    @ws.on 'open', =>
      log 'ws opened'
      @open = true
      @handlers.get('open')?.forEach (handler) -> handler this


    @ws.on 'close', =>
      log 'ws closed'
      @open = false
      @handlers.get('close')?.forEach (handler) -> handler this


    @ws.on 'start', (id) =>
      @id = id
      @handlers.get('start')?.forEach (handler) -> handler this


    @ws.on 'request offer', ({room, from}) =>
      log 'recieved request for offer'
      return unless @rooms.has room

      connection = new RTCPeerConnection @configuration
      dataChannel = connection.createDataChannel "#{room}:#{from}"

      dataChannel.addEventListener 'open', =>
        log 'data channel opened to peer'
        @handlers.get('peer')?.forEach (handler) -> handler room, from

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
        @handlers.get('peer')?.forEach (handler) -> handler room, from

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



  join: (room) ->
    return if @rooms.has room

    @ws.send 'join', room

    @rooms.add room

    @handlers.get('join')?.forEach (handler) -> handler room


  leave: (room) ->
    return unless @rooms.has room

    @ws.send 'leave', room

    @rooms.delete room
    @connections.get(room)?.forEach (connection) -> connection.close()
    @connections.delete room
    @channels.delete room

    @handlers.get('leave')?.forEach (handler) -> handler room


  on: (type, callback) ->
    @handlers.add type, callback


  off: (type, callback) ->
    if callback?
      @handlers.delete type, callback
    else
      @handlers.delete type


  send: (room, type, payload) ->
    message = JSON.stringify [type, payload]
    @channels.get(room)?.forEach (channel) -> channel.send message


