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
    server = new UltrawaveServer 5678
    client = new Ultrawave 'ws://localhost:5678'


  describe 'when a peer connects to a server', ->

    it 'the server should send "start" with the peer id', ->

    it 'the peer should set its id and set its open property to true', ->

    it 'the peer should trigger an open event', ->


  describe 'when a peer attempts to create a room', ->

    describe 'and the room already exists', ->

      it 'the peer should send "create" with the room name', ->

      it 'the server should send "create failed" with the room name', ->

      it 'the peer should run its failure callback', ->

    describe 'and the room does not yet exist', ->

      it 'the peer should send "create" with the room name', ->

      it 'the server should send "create" with the room name', ->

      it 'the peer should add the room to its rooms set', ->

      it 'the peer should trigger a join event', ->

      it 'the peer should run its success callback', ->


  describe 'when a peer attempts to join an existing room', ->

    describe 'and the room already exists', ->

      it 'the peer should send "create" with the room name', ->

      it 'the server should send "create" with the room name', ->

      it 'the peer should add the room to its rooms set', ->

      it 'the peer should trigger a join event', ->

      it 'the peer should run its success callback', ->

    describe 'and the room does not yet exist', ->

      it 'the peer should send "join" with the room name', ->

      it 'the server should send "join failed" with the room name', ->

      it 'the peer should run its failure callback', ->


  describe 'when a peer sends a message in a room', ->

  describe 'when a peer leaves a room', ->

  describe 'when a peer disconnects from a server', ->
