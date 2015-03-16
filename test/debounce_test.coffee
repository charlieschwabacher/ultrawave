assert = require 'assert'
debounce = require '../scripts/util/debounce'

describe 'debounce', ->

  it 'should run only once when called multiple times w/in interval', (done) ->
    count = 0
    increment = debounce 2, -> count += 1
    increment()
    increment()
    increment()

    setTimeout ->
      assert.equal count, 1
      done()
    , 4

