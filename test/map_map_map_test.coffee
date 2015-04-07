assert = require 'assert'
MapMapMap = require '../scripts/data_structures/map_map_map'

describe 'MapMapMap', ->

  it 'should set, has, and get', ->
    mapMapMap = new MapMapMap

    assert not mapMapMap.has 'a', 'b', 'c'

    mapMapMap.set 'a', 'b', 'c', 1

    assert mapMapMap.has 'a'
    assert mapMapMap.has 'a', 'b'
    assert mapMapMap.has 'a', 'b', 'c'

    assert mapMapMap.get('a', 'b', 'c') is 1

    mapMapMap.delete 'a', 'b', 'c'

    assert not mapMapMap.has 'a'
    assert not mapMapMap.has 'a', 'b'
    assert not mapMapMap.has 'a', 'b', 'c'

    assert not mapMapMap.get('a')?
