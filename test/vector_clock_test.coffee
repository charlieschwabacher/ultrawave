assert = require 'assert'
VectorClock = require '../scripts/vector_clock'


describe 'VectorClock', ->


  describe 'constructor', ->

    it 'should set id and initialize clock to 0', ->
      clock = new VectorClock id: 1
      assert clock.id is 1
      assert clock[1] is 0

    it 'should accept an initial clock', ->
      clock = new VectorClock id: 1, 1: 1, 2: 2, 3: 3
      assert clock.id is 1
      assert clock[1] is 1
      assert clock[2] is 2
      assert clock[3] is 3


  describe 'increment', ->

    it 'should increment the clock for id by one', ->
      clock = new VectorClock id: 1
      assert clock[1] is 0
      clock.increment()
      assert clock[1] is 1
      clock.increment()
      assert clock[1] is 2


  describe '#update', ->

    it 'should update clock', ->
      clock = new VectorClock id: 1, 1: 1, 2: 2, 3: 3
      clock.update {1: 11, 2: 12, 4: 14}
      assert clock[1] is 11
      assert clock[2] is 12
      assert clock[3] is 3
      assert clock[4] is 14


  describe '#laterThan', ->

    it 'should return true when provided clock is earlier', ->
      clock = new VectorClock id: 2, 1: 2, 2: 3, 3: 3
      other = {id: 1, 1: 1, 2: 2, 3: 3}
      assert clock.laterThan other

    it 'should return true when provided clock is concurrent and has higher id', ->
      clock = new VectorClock id: 1, 1: 2, 2: 2, 3: 3
      other = {id: 2, 1: 1, 2: 3, 3: 3}
      assert clock.laterThan other

    it 'should return false when a provided clock is later', ->
      clock = new VectorClock id: 1, 1: 1, 2: 2, 3: 3
      other = {id: 2, 1: 2, 2: 3, 3: 3}
      assert not clock.laterThan other

    it 'should return false when provided clock is concurrent and has lower id', ->
      clock = new VectorClock id: 2, 1: 2, 2: 2, 3: 3
      other = {id: 1, 1: 1, 2: 3, 3: 3}
      assert not clock.laterThan other
