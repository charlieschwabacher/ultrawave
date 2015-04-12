# mock browser environment

global.WebSocket = require 'ws'
global.window = require './rtc_mocks'

# require dependancies

assert = require 'assert'
GroupServer = require '../server/group_server'
PeerGroup = require '../scripts/peer_group'
Ultrawave = require '../scripts/ultrawave'
VectorClock = require '../scripts/vector_clock'
GroupServer.log = false
events = PeerGroup::events


port = 5500



setupRoom = (peers, roomName, callback) ->
  remainingPeers = peers.length * (peers.length - 1)
  peers.forEach (peer) ->
    peer.on events.start, -> peer.joinOrCreate roomName
    peer.on events.peer, -> callback() if (remainingPeers -= 1) is 0


describe 'Ultrawave:', ->

  describe '#_applyRemoteChange', ->

    it 'should apply changes directly when clock is later than last
        clock', (done) ->

      ultrawave = new Ultrawave "ws:localhost"

      clock = new VectorClock id: 'a', a: 2
      args = ['b',2]

      handle =
        data: -> {}
        set: ->
          assert.equal(arg, arguments[i]) for arg, i in args
          done()

      ultrawave.handles.set 'lobby', handle
      ultrawave.clocks.set 'lobby', new VectorClock id: 'a', a: 1
      ultrawave.changes.map.set 'lobby', []

      ultrawave._applyRemoteChange 'lobby', clock, 'set', args

    it 'should ignore changes that have already been applied', ->

      ultrawave = new Ultrawave "ws:localhost"

      clock = new VectorClock id: 'a', a: 2
      args = [1,2]

      handle =
        data: -> {}
        set: -> throw new Error 'this should not be called'

      ultrawave.handles.set 'lobby', handle
      ultrawave.clocks.set 'lobby', new VectorClock id: 'a', a: 3
      ultrawave.changes.map.set 'lobby', [[{}, {id: 'a', a: 2}, 'set', [1,2]]]

      ultrawave._applyRemoteChange 'lobby', clock, 'set', args


    it 'should apply changes in order when clock is before earlier
        clock', (done) ->

      ultrawave = new Ultrawave "ws:localhost"

      changes = [
        [{}, {id: 'a', a: 1}, 'set', [0,1]]
        [{}, {id: 'a', a: 3}, 'set', [1,1]]
      ]

      setCalls = 0

      handle =
        data: -> {}
        set: (path, value) ->
          setCalls += 1

          # it should reset the data
          if setCalls is 1
            assert.deepEqual path, []
            assert.equal value, changes[0][0]
          # then apply our new change
          if setCalls is 2
            assert.equal path, 1
            assert.equal value, 2
          # than apply the last change
          if setCalls is 3
            assert.equal path, 1
            assert.equal value, 1
            done()

      ultrawave.handles.set 'lobby', handle
      ultrawave.clocks.set 'lobby', new VectorClock id: 'a', a: 3
      ultrawave.changes.map.set 'lobby', changes

      clock = new VectorClock id: 'a', a: 2
      ultrawave._applyRemoteChange 'lobby', clock, 'set', [1, 2]


    it 'should use peer id to resolve ambiguous ordering of chnages', ->

      ultrawave = new Ultrawave "ws:localhost"

      handle =
        data: -> {}
        set: (path, value) ->
          assert.equal path, 1
          assert.equal value, 3

      ultrawave.handles.set 'lobby', handle
      ultrawave.clocks.set 'lobby', new VectorClock id: 'b', a: 1, b: 0
      ultrawave.changes.map.set 'lobby', [
        [{}, {id: 'b', a: 1, b: 0}, 'set', [1,2]]
      ]

      clock = new VectorClock id: 'a', a: 0, b: 1
      ultrawave._applyRemoteChange 'lobby', clock, 'set', [1,3]


  describe 'when a peer requests a document', ->

    it 'the peer should send "request document" to the first peer it
        connects to', (done) ->

      server = new GroupServer port += 1
      client1 = new Ultrawave "ws:localhost:#{port}"
      client2 = new Ultrawave "ws:localhost:#{port}"

      client1.peerGroup.on 'request document', -> done()

      client1
        .create('lobby', {}, ->)
        .then ->
          client2.join 'lobby', ->

    it 'the peer receiving "request document" should respond with "document",
        its current document state, and its clock', (done) ->

      server = new GroupServer port += 1
      client1 = new Ultrawave "ws:localhost:#{port}"
      client2 = new Ultrawave "ws:localhost:#{port}"

      client2.peerGroup.on 'document', -> done()

      client1
        .create('lobby', {}, ->)
        .then -> client2.join 'lobby', ->

    it 'the peer should send "request changes" to each other peer with the clock
        it received from the first peer', (done) ->

      server = new GroupServer port += 1
      client1 = new Ultrawave "ws:localhost:#{port}"
      client2 = new Ultrawave "ws:localhost:#{port}"
      client3 = new Ultrawave "ws:localhost:#{port}"

      # we don't know who will send the document request, so one of these two
      # peers will get request changes
      client1.peerGroup.on 'request changes', -> done()
      client2.peerGroup.on 'request changes', -> done()

      client1
        .create('lobby', {}, ->)
        .then -> client2.join('lobby', ->)
        .then -> client3.join('lobby', ->)

    it 'peers receiving "request changes" should send any changes they have made
        after the attached clock to the requsting peer', (done) ->

      server = new GroupServer port += 1
      client = new Ultrawave "ws:localhost:#{port}"

      client.create('lobby', {}, ->).then ->
        clock = {id: 'a', a: 1}
        method = 'set'
        args = []

        client.changes.set 'lobby', [{}, clock, method, args]

        client.peerGroup.sendTo = (group, id, type, payload) ->
          assert.equal group, 'lobby'
          assert.equal id, 1
          assert.equal type, method
          assert.deepEqual payload, {clock, args}
          done()

        client.peerGroup.trigger 'request changes', 'lobby', 1, {id: 'b', a: 0}


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

