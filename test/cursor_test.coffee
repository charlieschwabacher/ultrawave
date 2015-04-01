assert = require 'assert'
Cursor = require '../scripts/util/cursor'



describe 'Cursor', ->

  initialData =
    a:
      b:
        c: 1
        d: 2
      e: [1, 2, 3]


  root = null
  handle = null



  beforeEach ->
    handle = Cursor.create initialData, (_root) -> root = _root



  it 'should inherit from an exposed class', ->
    assert root instanceof Cursor.Cursor


  it 'should trigger its callback immediately', ->
    count = 0
    Cursor.create {}, -> count += 1
    assert count is 1


  it 'should trigger a callback only once for multiple changes', (done) ->
    root = null
    count = 0
    Cursor.create {}, (_root) ->
      count += 1
      root = _root
    root.set 'a', 1
    root.set 'b', 2
    root.set 'c', 3
    setTimeout ->
      assert count is 2
      done()


  describe '#get', ->

    it 'should preserve identity of data', ->
      assert root.get() is initialData

    it 'should return references to the same object in subsequent calls', ->
      assert root.get('a') is root.get('a')

    it 'should return expected values', ->
      assert root.get(['a', 'b', 'c']) is 1
      assert root.get(['a', 'b', 'd']) is 2


  describe '#set', ->

    it 'should set root value when called with one argument', ->
      root.set 7
      assert root.get() is 7
      assert root.get(['a', 'b', 'c']) is undefined

    it 'should set at path when called with two arguments', ->
      root.set ['a', 'e'], 3
      assert root.get(['a', 'e']) is 3

    it 'should replace parent objects', ->
      root.set ['a', 'e'], 3
      assert root.get() isnt initialData
      assert root.get('a') isnt initialData.a

    it 'should not replace objects that are not ancestors of changed value', ->
      root.set ['a', 'e'], 3
      assert root.get(['a', 'b']) is initialData.a.b

    it 'should clear keys below an object when set', ->
      root.set 'f', 11
      root.set [], {}
      assert root.get('a') is undefined
      assert root.get('f') is undefined


  describe '#cursor', ->

    # references to cursors should be cached so that two cursors w/ identical
    # path will be referentially equal if their target object is unchanged
    it 'should cache refrences to cursors', ->
      assert root.cursor('a') is root.cursor('a')
      assert root.cursor(['a', 'b']) is root.cursor('a').cursor('b')

    # changes to the target of a cursor should clear its cached reference so
    # that any new cursor sharing its path will no longer be referentially equal
    it 'should clear cached cursors when a value is changed', ->
      cursor = root.cursor 'a'
      root.set ['a', 'e'], 4
      assert root.cursor('a') isnt cursor

    # cache keys for values at different paths should not collide
    it 'works when two cursors point to equal values', ->
      root.set ['a', 'b', 'c'], 2
      c1 = root.cursor ['a', 'b', 'd']
      c2 = root.cursor ['a', 'b', 'c']
      assert c1 isnt c2


  describe '#push', ->

    it 'should append a value to the end of an array', ->
      root.push ['a', 'e'], 4
      assert.deepEqual root.get(['a', 'e']), [1, 2, 3, 4]

    it 'should throw an error if the target path does not contain an array', ->
      assert.throws -> root.push ['a', 'b'], 4

    it 'should clear cached cursors along changed paths', ->
      cursor = root.cursor 'a'
      root.push ['a', 'e'], 4
      assert root.cursor('a') isnt cursor


  describe '#pop', ->

    it 'should remove a value from the end of an array', ->
      val = root.pop ['a', 'e']
      assert val is 3
      assert.deepEqual root.get(['a', 'e']), [1, 2]

    it 'should throw an error if the target path does not contain an array', ->
      assert.throws -> root.pop ['a', 'b']

    it 'should clear cached cursors along changed paths', ->
      cursor = root.cursor 'a'
      root.pop ['a', 'e']
      assert root.cursor('a') isnt cursor


  describe '#unshift', ->

    it 'should prepend a value to the beginning of an array', ->
      root.unshift ['a', 'e'], 0
      assert.deepEqual root.get(['a', 'e']), [0, 1, 2, 3]

    it 'should throw an error if the target path does not contain an array', ->
      assert.throws -> root.unshift ['a', 'b'], 0

    it 'should clear cached cursors along changed paths', ->
      cursor = root.cursor 'a'
      root.unshift ['a', 'e'], 0
      assert root.cursor('a') isnt cursor

      # elements in the array have all moved back by one index
      cursor = root.cursor ['a', 'e', 1]
      root.unshift ['a', 'e'], 0
      assert root.cursor(['a', 'e', 1]) isnt cursor
      assert root.cursor(['a', 'e', 2]) is cursor


  describe '#shift', ->

    it 'should remove a value from the beginning of an array', ->
      val = root.shift ['a', 'e']
      assert.equal val, 1
      assert.deepEqual root.get(['a', 'e']), [2, 3]

    it 'should throw an error if the target path does not contain an array', ->
      assert.throws -> root.shift ['a', 'b']

    it 'should clear cached cursors along changed paths', ->
      cursor = root.cursor 'a'
      root.shift ['a', 'e']
      assert root.cursor('a') isnt cursor

      # elements in the array have all moved forward by one index
      cursor = root.cursor ['a', 'e', 1]
      root.shift ['a', 'e']
      assert root.cursor(['a', 'e', 1]) isnt cursor
      assert root.cursor(['a', 'e', 0]) is cursor


  describe '#splice', ->

    it 'should insert values into an array', ->
      root.splice ['a', 'e'], 1, 0, 1, 2
      assert.deepEqual root.get(['a', 'e']), [1, 1, 2, 2, 3]

    it 'should delete values from an array', ->
      root.splice ['a', 'e'], 1, 2
      assert.deepEqual root.get(['a', 'e']), [1]

    it 'should replace values in an array', ->
      root.splice ['a', 'e'], 1, 2, 4, 5
      assert.deepEqual root.get(['a', 'e']), [1, 4, 5]

    it 'should throw an error if the target path does not contain an array', ->
      assert.throws -> root.insertAt ['a', 'e'], 1, [1, 2]

    it 'should not clear cursor for other elements when replacing an element
       in the array', ->

      cursor1 = root.cursor ['a', 'e', 0]
      cursor2 = root.cursor ['a', 'e', 1]
      cursor3 = root.cursor ['a', 'e', 2]
      root.splice ['a', 'e'], 1, 1, 8
      assert root.cursor(['a', 'e', 0]) is cursor1
      assert root.cursor(['a', 'e', 1]) isnt cursor2
      assert root.cursor(['a', 'e', 2]) is cursor3

    it 'should clear cursors for following but not preceding elements when
       adding an element to the array', ->

      cursor1 = root.cursor ['a', 'e', 0]
      cursor2 = root.cursor ['a', 'e', 1]
      cursor3 = root.cursor ['a', 'e', 2]
      root.splice ['a', 'e'], 1, 1, 5, 6
      assert root.cursor(['a', 'e', 0]) is cursor1
      assert root.cursor(['a', 'e', 1]) isnt cursor2
      assert root.cursor(['a', 'e', 2]) isnt cursor3

    it 'should clear cursors for following but not preceding elements when
       removing an element from the array', ->

      cursor1 = root.cursor ['a', 'e', 0]
      cursor2 = root.cursor ['a', 'e', 1]
      cursor3 = root.cursor ['a', 'e', 2]
      root.splice ['a', 'e'], 1, 1
      assert root.cursor(['a', 'e', 0]) is cursor1
      assert root.cursor(['a', 'e', 1]) isnt cursor2
      assert root.cursor(['a', 'e', 2]) isnt cursor3



  describe '#merge', ->

    it 'should set multiple keys at once', ->
      root.merge {a: b: c: 8, d: 9}
      assert.equal root.get(['a', 'b', 'c']), 8
      assert.equal root.get(['a', 'b', 'd']), 9

    it 'should not clear existing data', ->
      root.set ['a', 'e'], 4
      assert.equal root.get(['a', 'e']), 4
      assert.equal root.get(['a', 'b', 'c']), 1

    it 'should clear cached cursors along changed paths', ->
      assert.equal handle.cache().size(), 0, 'cache should initially be empty'

      cursor1 = root.cursor ['a', 'b']
      cursor2 = root.cursor ['a', 'e']

      assert.equal handle.cache().size(), 3, 'we have stored 3 nodes'

      root.merge a: b: c: 10

      # the cursor at ['a', 'e'] should still be cached, meaning 2 nodes
      assert.equal handle.cache().size(), 2, '[a, e] should still be cached'

      assert.notEqual root.cursor(['a', 'b']), cursor1, 'this should be cleared'
      assert.equal root.cursor(['a', 'e']), cursor2, 'this should be cached'


  describe 'setting data through subcursors', ->

    it 'should set data in the global object', ->
      cursor = root.cursor ['a', 'e']
      cursor.set [], 4
      assert root.get(['a', 'e']) is 4

    it 'should clear cached cursors when a value is changed', ->
      cursor = root.cursor ['a', 'e']
      cursor.set [], 4
      assert root.cursor(['a', 'e']) isnt cursor


  describe 'multiple cursors', ->

    # setting through cursors should work as expected even if changes have been
    # made to the underlying data after their creation
    it 'should set data when root object has changed after cursor creating', ->
      cursor1 = root.cursor ['a', 'b', 'c']
      cursor2 = root.cursor ['a', 'b', 'd']
      assert cursor1.get() is 1
      assert cursor2.get() is 2
      cursor1.set [], 5
      assert cursor1.get() is 5
      assert cursor2.get() is 2
      cursor2.set [], 6
      assert cursor1.get() is 5
      assert cursor2.get() is 6
      assert root.get(['a', 'b', 'c']) is 5
      assert root.get(['a', 'b', 'd']) is 6


  describe 'creating an empty cursor', ->

    it 'should create a cursor with null root node', ->
      Cursor.create null, (cursor) -> root = cursor
      assert root.get() is null

