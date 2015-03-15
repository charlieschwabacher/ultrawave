WSServer = require './ws_server'
MapSet = require '../scripts/util/map_set'


log = (message) -> console.log message



module.exports = class UltrawaveServer


  constructor: ->

    @wss = new WSServer
    @rooms = new MapSet
    @memberships = new MapSet


    @wss.on 'open', (id) =>
      log "opened connection to #{id}"
      @wss.send id, 'start', id


    @wss.on 'close', (id) =>
      log "closed connection to #{id}"

      @memberships.get(id).forEach (room) =>
        @rooms.delete room, id

      @memberships.delete id


    @wss.on 'join', (id, room) =>
      log "client #{id} joined #{room}"

      @rooms.get(room)?.forEach (peer) =>
        log "requsting offer from #{peer} in #{room}"
        @wss.send peer, 'request offer', {room, from: id}

      @memberships.add id, room
      @rooms.add room, id


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
    @wss.close()


