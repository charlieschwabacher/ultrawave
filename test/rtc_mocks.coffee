MapSet = require '../scripts/data_structures/map_set'

directory = new Map

peerId = 0



EventTarget =

  addEventListener: (event, callback) ->
    @handlers ||= new MapSet
    @handlers.add event, callback

  removeEventListener: (event, callback) ->
    @handlers?.delete event, callback

  trigger: (event, args...) ->
    @handlers.get(event)?.forEach (handler) -> handler.apply null, args



class RTCPeerConnection
  @::[k] = v for k, v of EventTarget

  constructor: (configuration) ->
    @signalingState = 'stable'
    @id = peerId += 1
    @targetId = null
    @dataChannel = new RTCDataChannel this
    directory.set @id, this

  createDataChannel: (name) ->
    @dataChannel

  createOffer: (cb) ->
    setTimeout => cb new RTCSessionDescription sdp: @id, type: 'offer'

  createAnswer: (cb) ->
    setTimeout => cb new RTCSessionDescription sdp: @id, type: 'answer'

  setLocalDescription: (localDescription, cb) ->
    setTimeout =>
      if @signalingState is 'stable'
        @signalingState = 'have-local-offer'
      else
        @signalingState = 'stable'
        @trigger 'icecandidate', {candidate: @id}

      @trigger 'signalingstatechange'

      cb?()

  setRemoteDescription: (remoteDescription, cb) ->
    setTimeout =>
      @targetId = remoteDescription.sdp

      if @signalingState is 'stable'
        @signalingState = 'have-remote-offer'
      else
        @signalingState = 'stable'
        @trigger 'icecandidate', {candidate: @id}

      @trigger 'signalingstatechange'

      cb?()

  addIceCandidate: (candidate, cb) ->
    setTimeout =>
      @trigger 'datachannel', channel: @dataChannel
      setTimeout =>
        @dataChannel.trigger 'open'
      cb?()

  close: ->
    @signalingState = 'closed'
    @trigger 'signalingstatechange'
    @dataChannel.trigger 'close'
    target = directory.get @targetId
    target.signalingState = 'closed'
    target.trigger 'signalingstatechange'
    target.dataChannel.trigger 'close'
    directory.delete @id
    directory.delete @targetId



class RTCDataChannel
  @::[k] = v for k, v of EventTarget

  constructor: (@connection) ->

  send: (data) ->
    target = directory.get(@connection.targetId).dataChannel
    target.trigger 'message', {data}



class RTCSessionDescription

  constructor: ({sdp, type}) ->
    @sdp = sdp
    @type = type


class RTCIceCandidate

  constructor: ->




module.exports = {RTCPeerConnection, RTCSessionDescription, RTCIceCandidate}
