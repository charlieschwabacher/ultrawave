# mock browser environment

global.WebSocket = require 'ws'
global.window = require './rtc_mocks'

# require dependancies

assert = require 'assert'
UltrawaveServer = require '../server/ultrawave_server'
UltrawaveServer.log = false

port = 5000



setupRoom = (peers, roomName, callback) ->
  remainingPeers = peers.length * (peers.length - 1)
  peers.forEach (peer) ->
    peer.on events.start, -> peer.joinOrCreate roomName
    peer.on events.peer, -> callback() if (remainingPeers -= 1) is 0


describe 'Wormhole', ->

  describe 'when a peer requests an existing document', ->

    it 'the peer should send \'request document\' to the first existing
        peer it connects to', ->

    it 'the peer receiving request document should respond wiht \'document\',
        the current document, and its clock', ->

    it 'the peer should send '

  describe ''
