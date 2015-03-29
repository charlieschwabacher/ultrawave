WSServer = require './ws_server'
MapSet = require '../scripts/util/map_set'


log = (message) -> console.log message if UltrawaveServer.log



module.exports = class UltrawaveServer


  @log: true


  constructor: (port) ->
    log "starting ultrawave server on port #{port}"

    @wss = new WSServer {port}

    # map room names to sets of peer ids
    @rooms = new MapSet

    # map peer ids to sets of room names
    @memberships = new MapSet


    @wss.on 'open', (id) =>
      log "opened connection to #{id}"
      @wss.send id, 'start', id


    @wss.on 'close', (id) =>
      log "closed connection to #{id}"

      @memberships.get(id)?.forEach (room) =>
        @rooms.delete room, id

      @memberships.delete id


    @wss.on 'create', (id, room) =>
      if @rooms.has room
        log "client #{id} failed to create #{room}"
        @wss.send id, 'create failed', room
      else
        log "client #{id} created #{room}"
        @memberships.add id, room
        @rooms.add room, id
        @wss.send id, 'create', room


    @wss.on 'join', (id, room) =>
      if peers = @rooms.get room
        log "client #{id} joined #{room}"
        peers.forEach (peer) =>
          log "requsting offer from #{peer} in #{room}"
          @wss.send peer, 'request offer', {room, from: id}
        @memberships.add id, room
        @rooms.add room, id
        @wss.send id, 'join', room
      else
        log "client #{id} failed to join #{room}"
        @wss.send id, 'join failed', room


    @wss.on 'leave', (id, room) =>
      log "client #{id} left #{room}"

      @memberships.delete id, room
      @rooms.delete room, id


    @wss.on 'offer', (id, {sdp, room, to}) =>
      log "client #{id} sent offer to #{to} in #{room}"
      @wss.send to, 'offer', {sdp, room, from: id}


    @wss.on 'answer', (id, {sdp, room, to}) =>
      log "client #{id} sent answer to #{to} in #{room}"
      @wss.send to, 'answer', {sdp, room, from: id}


    @wss.on 'candidate', (id, {candidate, room, to}) =>
      log "client #{id} sent ice candidate to #{to} in #{room}"
      @wss.send to, 'candidate', {candidate, room, from: id}



  stop: ->
    log 'stopping ultrawave server'
    @wss.close()


