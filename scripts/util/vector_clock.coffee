MapSet = require './map_set'


__missing = Symbol 'missing'


module.exports = class VectorClock

  @__missing: __missing

  constructor: (@id, clock) ->
    @[__missing] = new MapSet
    @[key] = value for key, value of clock
    @[@id] ||= 0

  increment: ->
    @[@id] += 1

  update: (clock) ->
    for own id, tick of clock
      id = parseInt id

      if latest = @[id]
        @[id] = Math.max latest, tick
      else
        @[id] = tick

      # keep track of missing updates
      @[__missing].delete id, tick
      if tick - (latest or 0) > 1
        for i in [(latest + 1)...tick]
          @[__missing].add id, i

  laterThan: (clock) ->
    later = false
    earlier = false
    for own id, tick of clock
      if @[id] < clock[id]
        earlier = true
      else if @[id] > clock[id]
        later = true

    if later and not earlier
      true
    else if earlier and not later
      false
    else
      @id < clock.id

  applied: (id, tick) ->
    @[id] >= tick and not @[__missing].has id, tick