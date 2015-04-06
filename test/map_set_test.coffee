assert = require 'assert'
MapSet = require '../scripts/data_structures/map_set'

describe 'MapSet', ->

  it 'should add, has, and delete', ->
    mapSet = new MapSet

    assert not mapSet.has 'a', 1

    mapSet.add 'a', 1
    assert mapSet.has 'a', 1

    mapSet.delete 'a', 1
    assert not mapSet.has 'a', 1
    assert not mapSet.get('a')?
