# mock browser environment

global.WebSocket = require 'ws'
global.window = require './rtc_mocks'

# require dependancies

assert = require 'assert'
GroupServer = require '../server/ultrawave_server'
Ultrawave = require '../scripts/wormhole'
VectorClock = require '../scripts/vector_clock'
GroupServer.log = false

port = 5500



setupRoom = (peers, roomName, callback) ->
  remainingPeers = peers.length * (peers.length - 1)
  peers.forEach (peer) ->
    peer.on events.start, -> peer.joinOrCreate roomName
    peer.on events.peer, -> callback() if (remainingPeers -= 1) is 0


describe 'Ultrawave:', ->

  describe '#applyRemoteChange', ->

    it 'should apply changes directly when clock is later than last
        clock', (done) ->

      wormhole = new Ultrawave "ws:localhost"

      clock = new VectorClock 0, {0: 2}
      args = [1,2,3]

      wormhole.clocks.set 'lobby', new VectorClock 0, {0: 1}
      wormhole.changes.set 'lobby', []
      wormhole.handles.set 'lobby', data: (-> {}), set: ->
        assert.equal(arg, arguments[i]) for arg, i in args
        done()

      wormhole.applyRemoteChange 'lobby', clock, 'set', args

    it 'should ignore changes that have already been applied', ->

    it 'should apply changes in order when clock is before earlier clock', ->

    it 'should use peer id to resolve ambiguous ordering of chnages', ->


  describe 'when a peer requests a document', ->

    it 'the peer should send "request document" to the first peer it
        connects to', ->
      server = new GroupServer port += 1
      client = new Ultrawave "ws:localhost:#{port}"


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

