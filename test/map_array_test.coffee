assert = require 'assert'
MapArray = require '../scripts/util/map_array'

describe 'MapArray', ->

  it 'should push and get', ->
    MapArray = new MapArray

    assert not MapArray.get('a')?

    MapArray.push 'a', 1
    assert.deepEqual MapArray.get('a'), [1]

    MapArray.push 'a', 2
    assert.deepEqual MapArray.get('a'), [1, 2]
