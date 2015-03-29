MapSet = require '../scripts/util/map_set'

directory = new Map

peerId = 0


EventTarget =

  addEventListener: (event, callback) ->
    @handlers ||= new MapSat
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

    @directory.set @id, this

  createDataChannel: (name) ->
    dc = new RTCDataChannel this
    directory.get(@targetId).trigger

  createOffer: (cb) ->
    setTimeout => cb @id

  createAnswer: (cb) ->
    setTimeout => cb @id

  setLocalDescription: (localDescription, cb) ->
    setTimeout =>
      cb()

  setRemoteDescription: (remoteDescription, cb) ->
    setTimeout =>
      @targetId = remoteDescription.id
      cb()

  addIceCandidate: (candidate, cb) ->


  close: ->
    @signalingState = 'closed'
    @directory.delete @id, this


class RTCDataChannel
  @::[k] = v for k, v of EventTarget

  constructor: (@connection) ->



class RTCSessionDescription

  constructor: (configuration) ->


class RTCIceCandidate

  constructor: (candidate) ->



module.exports = {RTCPeerConnection, RTCSessionDescription, RTCIceCandidate}
