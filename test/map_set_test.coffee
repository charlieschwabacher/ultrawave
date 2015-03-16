assert = require 'assert'
MapSet = require '../scripts/util/map_set'

describe 'MapSet', ->

  it 'should set and get', ->
    mapSet = new MapSet

    assert not mapSet.has 'a', 1

    mapSet.add 'a', 1
    assert mapSet.has 'a', 1

    mapSet.delete 'a', 1
    assert not mapSet.has 'a', 1
    assert not mapSet.get('a')?