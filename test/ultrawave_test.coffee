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

UltrawaveServer::shouldSend = (expectedId, expectedType, expectedPaylod, done) ->
  @wss.send = (id, type, payload) ->
    assert.equal id, expectedId
    assert.equal type, expectedType
    assert.equal payload, expectedPaylod
    done()


describe 'Ultrawave', ->

  describe 'when a peer connects to a server', ->

    it 'the peer should trigger an open event and set its open property', (done) ->
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

      it 'the peer should run its failure callback', (done) ->
        server = new UltrawaveServer port += 1
        client = new Ultrawave "ws:localhost:#{port}"
        server.rooms.map.set 'lobby', new Set
        client.on events.open, ->
          client.create 'lobby', (->), done


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
          client.create 'lobby', ->
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
          client.create 'lobby', done


  describe 'when a peer attempts to join an existing room', ->

    it 'the peer should send "join" with the room name', (done) ->
      server = new UltrawaveServer port += 1
      client = new Ultrawave "ws:localhost:#{port}"
      client.shouldSend 'join', 'lobby', done
      client.join 'lobby'


    describe 'and the room already exists', ->

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
          client.join 'lobby', ->
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
          client.join 'lobby', done

    describe 'and the room does not yet exist', ->

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
          client.join 'lobby', (->), done


  describe 'when a peer sends a message in a room', ->

    it 'the peers should each receive the message and trigger handlers', (done) ->
      server = new UltrawaveServer port += 1
      clients = [1..3].map -> new Ultrawave "ws:localhost:#{port}"

      # start after all clients have joined 'lobby'
      ready = 0
      clients.forEach (client, i) ->
        client.on events.start, -> client.joinOrCreate 'lobby'
        client.on events.join, ->
          console.log 'join'
          start() if (ready += 1) is clients.length

      # client at index zero sends a message, all other clients should receive it
      start = ->
        console.log 'starting!'
        received = 0
        clients.slice(1).forEach (client) ->
          client.on 'message', (room, id, payload) ->
            assert.equal room, 'lobby'
            assert.equal id, clients[0].id
            assert.equal payload, 'testing'
            done() if (recevied += 1) is clients.length - 1

        clients[0].send 'lobby', 'message', 'testing'


  # describe 'when a peer leaves a room', ->

  #   it 'the server should remove the user from its list of room members', (done) ->

  #   it 'the peers should clean up their closed connections', (done) ->


  # describe 'when a peer disconnects from a server', ->

  #   it 'the server should clean up references to the user', (done) ->

  #   it 'the peers should clean up their closed connections', (done) ->
