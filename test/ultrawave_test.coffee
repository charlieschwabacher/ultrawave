# mock browser environment

global.WebSocket = require 'ws'
global.window = require './rtc_mocks'

# require dependancies

assert = require 'assert'
Ultrawave = require '../scripts/util/ultrawave'
UltrawaveServer = require '../server/ultrawave_server'
UltrawaveServer.log = false
events = Ultrawave::events

port = 5000



# extend server and client classes with some expectation methods

Ultrawave::shouldSend = (expectedType, expectedPaylod, done) ->
  @ws.send = (type, payload) ->
    assert.equal type, expectedType
    assert.equal payload, expectedPaylod
    done()

UltrawaveServer::shouldSend = (
  (expectedId, expectedType, expectedPayload, done) ->
    @wss.send = (id, type, payload) ->
      assert.equal id, expectedId
      assert.equal type, expectedType
      assert.equal payload, expectedPayload
      done()
)

setupRoom = (peers, roomName, callback) ->
  remainingPeers = peers.length * (peers.length - 1)
  peers.forEach (peer) ->
    peer.on events.start, -> peer.joinOrCreate roomName
    peer.on events.peer, -> callback() if (remainingPeers -= 1) is 0


describe 'Ultrawave:', ->

  describe 'when a peer connects to a server', ->

    it 'the peer should trigger an open event and set open property', (done) ->
      server = new UltrawaveServer port += 1
      client = new Ultrawave "ws:localhost:#{port}"
      assert client.open is false
      client.on events.open, ->
        assert client.open is true
        done()

    it 'the server should send "start" with the peer id', (done) ->
      server = new UltrawaveServer port += 1
      server.wss.send = (id, type, payload) ->
        assert.equal type, 'start'
        assert.equal payload, id
        done()
      client = new Ultrawave "ws:localhost:#{port}"

    it 'the peer should set its id', ->
      server = new UltrawaveServer port += 1
      client = new Ultrawave "ws:localhost:#{port}"
      assert.strictEqual client.id, null
      client.ws.trigger 'start', 'abc'
      assert.equal client.id, 'abc'


  describe 'when a peer attempts to create a room', ->

    it 'the peer should send "create" with the room name', (done) ->
      server = new UltrawaveServer port += 1
      client = new Ultrawave "ws:localhost:#{port}"
      client.shouldSend 'create', 'lobby', done
      client.create 'lobby'


    describe 'and the room already exists', ->

      it 'the server should send "create failed" with the room name', (done) ->
        server = new UltrawaveServer port += 1
        client = new Ultrawave "ws:localhost:#{port}"
        server.rooms.map.set 'lobby', new Set
        client.on events.start, ->
          server.shouldSend client.id, 'create failed', 'lobby', done
          client.create 'lobby'

      it 'the peer should return and reject a promise', (done) ->
        server = new UltrawaveServer port += 1
        client = new Ultrawave "ws:localhost:#{port}"
        server.rooms.map.set 'lobby', new Set
        client.on events.open, -> client.create('lobby').catch done


    describe 'and the room does not yet exist', ->

      it 'the server should send "create" with the room name', (done) ->
        server = new UltrawaveServer port += 1
        client = new Ultrawave "ws:localhost:#{port}"
        client.on events.start, ->
          server.shouldSend client.id, 'create', 'lobby', done
          client.create 'lobby'

      it 'the peer should add the room to its rooms set', (done) ->
        server = new UltrawaveServer port += 1
        client = new Ultrawave "ws:localhost:#{port}"
        client.on events.open, ->
          client.create('lobby').then ->
            assert client.rooms.has 'lobby'
            done()

      it 'the peer should trigger a join event with the room', (done) ->
        server = new UltrawaveServer port += 1
        client = new Ultrawave "ws:localhost:#{port}"
        client.on events.join, (room) ->
          assert.equal room, 'lobby'
          done()
        client.on events.open, ->
          client.create 'lobby'

      it 'the peer should run its success callback', (done) ->
        server = new UltrawaveServer port += 1
        client = new Ultrawave "ws:localhost:#{port}"
        client.on events.open, ->
          client.create('lobby').then done


  describe 'when a peer attempts to join an existing room', ->

    it 'the peer should send "join" with the room name', (done) ->
      server = new UltrawaveServer port += 1
      client = new Ultrawave "ws:localhost:#{port}"
      client.shouldSend 'join', 'lobby', done
      client.join 'lobby'


    describe 'and the room already exists,', ->

      it 'the server should send "join" with the room name', (done) ->
        server = new UltrawaveServer port += 1
        client = new Ultrawave "ws:localhost:#{port}"
        server.rooms.map.set 'lobby', new Set
        client.on events.start, ->
          server.shouldSend client.id, 'join', 'lobby', done
          client.join 'lobby'

      it 'the peer should add the room to its rooms set', (done) ->
        server = new UltrawaveServer port += 1
        client = new Ultrawave "ws:localhost:#{port}"
        server.rooms.map.set 'lobby', new Set
        client.on events.open, ->
          client.join('lobby').then ->
            assert client.rooms.has 'lobby'
            done()

      it 'the peer should trigger a join event with the room', (done) ->
        server = new UltrawaveServer port += 1
        client = new Ultrawave "ws:localhost:#{port}"
        server.rooms.map.set 'lobby', new Set
        client.on events.join, (room) ->
          assert.equal room, 'lobby'
          done()
        client.on events.open, ->
          client.join 'lobby'

      it 'the peer should run its success callback', (done) ->
        server = new UltrawaveServer port += 1
        client = new Ultrawave "ws:localhost:#{port}"
        server.rooms.map.set 'lobby', new Set
        client.on events.open, ->
          client.join('lobby').then done

    describe 'and the room does not yet exist,', ->

      it 'the server should send "join failed" with the room name', (done) ->
        server = new UltrawaveServer port += 1
        client = new Ultrawave "ws:localhost:#{port}"
        client.on events.start, ->
          server.shouldSend client.id, 'join failed', 'lobby', done
          client.join 'lobby'

      it 'the peer should run its failure callback', (done) ->
        server = new UltrawaveServer port += 1
        client = new Ultrawave "ws:localhost:#{port}"
        client.on events.open, ->
          client.join('lobby').catch done


  describe 'when a peer sends a message in a room', ->

    it 'the peers should each receive the message and trigger events', (done) ->
      server = new UltrawaveServer port += 1
      peers = [1..3].map -> new Ultrawave "ws:localhost:#{port}"
      setupRoom peers, 'lobby', ->

        # first peer sends a message, all others should receive it
        remainingMessages = peers.length - 1
        peers.slice(1).forEach (peer) ->
          peer.on 'message', (room, id, payload) ->
            assert.equal room, 'lobby'
            assert.equal id, peers[0].id
            assert.equal payload, 'testing'
            done() if (remainingMessages -= 1) is 0

        peers[0].send 'lobby', 'message', 'testing'


  describe 'when a peer leaves a room', ->

    it 'the server should remove the user from list of room members', (done) ->
      server = new UltrawaveServer port += 1
      client = new Ultrawave "ws:localhost:#{port}"
      server.rooms.add 'lobby', 'abcd'
      client.on events.start, ->
        client.join('lobby').then ->
          assert server.rooms.has 'lobby', client.id
          assert server.memberships.has client.id, 'lobby'
          client.leave 'lobby'

          # we don't have a callback so set a 10ms timeout here to wait for
          # ws communication
          setTimeout ->
            assert not server.rooms.has 'lobby', client.id
            assert not server.memberships.has client.id, 'lobby'
            assert server.rooms.has 'lobby', 'abcd'
            done()
          , 10

    describe 'and the room becomes empty,', ->

    it 'the server should clean up references to the room if the room
        becomes empty', (done) ->
      server = new UltrawaveServer port += 1
      client = new Ultrawave "ws:localhost:#{port}"
      assert not server.rooms.has 'lobby'
      client.on events.start, ->
        client.create('lobby').then ->
          assert server.rooms.has 'lobby'
          client.leave 'lobby'

          # we don't have a callback so set a 10ms timeout here to wait for
          # ws communication
          setTimeout ->
            assert not server.rooms.has 'lobby'
            done()
          , 10

    it 'the peers should clean up their closed connections', (done) ->
      server = new UltrawaveServer port += 1
      peers = [1..3].map -> new Ultrawave "ws:localhost:#{port}"
      setupRoom peers, 'lobby', ->
        peers.forEach (peer) ->
          assert.equal peer.connections.get('lobby').size, 2
        peers[0].leave 'lobby'

        # we set timeout here to wait for p2p communication, because this is
        # mocked we can just run on the next tick
        setTimeout ->
          peers.slice(1).forEach (peer) ->
            assert.equal peer.connections.get('lobby').size, 1
          done()


  describe 'when a peer disconnects from a server', ->

    it 'the server should clean up references to the user', (done) ->
      server = new UltrawaveServer port += 1
      client = new Ultrawave "ws:localhost:#{port}"
      client.on events.start, ->
        client.create('lobby').then ->
          assert server.rooms.has 'lobby', client.id
          assert server.memberships.has client.id
          client.close()

          # we don't have a callback so set a 10ms timeout here to wait for
          # ws communication
          setTimeout ->
            assert not server.rooms.has 'lobby', client.id
            assert not server.memberships.has client.id
            done()
          , 10

    it 'the peers should clean up their closed connections', (done) ->
      server = new UltrawaveServer port += 1
      peers = [1..3].map -> new Ultrawave "ws:localhost:#{port}"
      setupRoom peers, 'lobby', ->
        peers.forEach (peer) ->
          assert.equal peer.connections.get('lobby').size, 2
        peers[0].close()

        # we set timeout here to wait for p2p communication, because this is
        # mocked we can just run on the next tick
        setTimeout ->
          peers.slice(1).forEach (peer) ->
            assert.equal peer.connections.get('lobby').size, 1
          done()


