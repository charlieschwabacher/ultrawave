assert = require 'assert'
MapMap = require '../scripts/util/map_map'

describe 'MapMap', ->

  it 'should set, has, and get', ->
    mapMap = new MapMap

    assert not mapMap.has 'a', 'b'

    mapMap.set 'a', 'b', 1
    assert mapMap.has 'a', 'b'
    assert mapMap.get('a', 'b') is 1

    mapMap.delete 'a', 'b'
    assert not mapMap.has 'a', 'b'
    assert not mapMap.get('a')?
