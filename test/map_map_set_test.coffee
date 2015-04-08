assert = require 'assert'
MapMapSet = require '../scripts/data_structures/map_map_set'

describe 'MapMapSet', ->

  it 'should add, has, and delete', ->
    mapMapSet = new MapMapSet

    assert not mapMapSet.has 'a', 'b', 1

    mapMapSet.add 'a', 'b', 1
    assert mapMapSet.has 'a', 'b', 1

    mapMapSet.delete 'a', 'b', 1
    assert not mapMapSet.has 'a', 'b', 1
    assert not mapMapSet.get('a')?
