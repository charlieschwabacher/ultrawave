# mock browser objects
global.WebSocket = require 'ws'
global.window =
  webkitRTCPeerConnection: ->
  RTCSessionDescription: ->
  RTCIceCandidate: ->


assert = require 'assert'
UltrawaveServer = require '../server/ultrawave_server'
Ultrawave = require '../scripts/util/ultrawave'


describe 'Ultrawave', ->

  server = null
  client = null
  beforeEach ->
    server?.stop()
    client?.close()
    server = new UltrawaveServer
    client = new Ultrawave


  describe 'when a peer connects to a server', ->

  describe 'when a peer creates a room', ->

  describe 'when a peer joins an existing room', ->

  describe 'when a peer sends a message in a room', ->

  describe 'when a peer leaves a room', ->

  describe 'when a peer disconnects from a server', ->
