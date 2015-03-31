# mock browser environment

global.WebSocket = require 'ws'
global.window = require './rtc_mocks'

# require dependancies

assert = require 'assert'
UltrawaveServer = require '../server/ultrawave_server'
Wormhole = require '../scripts/util/wormhole'
UltrawaveServer.log = false

port = 5000



setupRoom = (peers, roomName, callback) ->
  remainingPeers = peers.length * (peers.length - 1)
  peers.forEach (peer) ->
    peer.on events.start, -> peer.joinOrCreate roomName
    peer.on events.peer, -> callback() if (remainingPeers -= 1) is 0


describe 'Wormhole:', ->

  describe 'when a peer requests a document', ->

    it 'the peer should send "request document" to the first peer it
        connects to', ->
      server = new UltrawaveServer port += 1
      client = new Wormhole "ws:localhost:#{port}", (root) ->


    it 'the peer receiving "request document" should respond with "document",
        its current document state, and its clock', ->

    it 'the peer should send "request changes" to each other peer with the clock
        it received from the first peer', ->

    it 'peers receiving "request changes" should send any changes they have made
        after the attached clock to the requsting peer', ->


  describe 'when a peer makes a change to a document', ->

    it 'the peer should increment its vector clock', ->

    it 'the peer should make the change locally', ->

    it 'the peer should add the change and clock to its list of changes', ->

    it 'the peer should send "change" with the method, data, and clock to each
        other peer', ->


  describe 'when a peer gets a message indicating a change to the document', ->

    describe 'and the incoming clock is later than the current clock,', ->

      it 'the peer should apply the change', ->

      it 'the peer should add the change and clock to its list of changes', ->

      it 'the peer should update its clock', ->

    describe 'and the incoming clock is earlier than the current clock,', ->

      it 'the peer should rewind and apply changes in order', ->

      it 'the peer should add the change in place to its list of changes', ->

      it 'the peer should resolve conflicts in favor of the author with the
          lowest id', ->

    describe 'and the incoming clock indicates a missed message', ->

      it 'after a timeout, the peer should send a "request sync" message to the
          peer who made the last with the missing author id and clock ticks', ->

      it 'the peer receiving "request sync" should respond with "sync" and the
          requested changes', ->

      it 'after a second timeout, if the requesting peer has not received a
          "sync" response, it sends "request sync" to another peer', ->

