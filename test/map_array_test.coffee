assert = require 'assert'
MapArray = require '../src/data_structures/map_array'

describe 'MapArray', ->

  it 'should push and get', ->
    mapArray = new MapArray

    assert not mapArray.get('a')?

    mapArray.push 'a', 1
    assert.deepEqual mapArray.get('a'), [1]

    mapArray.push 'a', 2
    assert.deepEqual mapArray.get('a'), [1, 2]
