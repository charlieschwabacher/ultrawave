assert = require 'assert'
CursorCache = require '../scripts/cursor_cache'


logIterator = (iterator) ->
  console.log value while ({done, value} = iterator.next()) and not done



describe 'CursorCache', ->

  initialData =
    a:
      b:
        c: 1
        d: 2
      e: [1, 2, 3]


  cache = null



  beforeEach ->
    cache = new CursorCache -> initialData



  describe 'constructor', ->

    it 'should create an empty root node', ->

      assert cache.root.size is 0


  describe '#store and #get', ->

    it 'should store and retrieve a cached cursor', ->

      c1 = path: ['a', 'b', 'c']
      c2 = path: ['a', 'd', 'e']
      c3 = path: ['a']

      cache.store c1
      assert cache.get(['a', 'b', 'c']) is c1

      cache.store c2
      assert cache.get(['a', 'b', 'c']) is c1
      assert cache.get(['a', 'd', 'e']) is c2

      cache.store c3
      assert cache.get(['a', 'b', 'c']) is c1
      assert cache.get(['a', 'd', 'e']) is c2
      assert cache.get(['a']) is c3


  describe '#clearPath', ->

    it 'should clear all cursors along a path', ->
      c1 = path: ['a']
      c2 = path: ['a', 'b']
      c3 = path: ['a', 'b', 'c']
      c4 = path: ['a', 'e']

      cursors = [c1, c2, c3, c4]
      cache.store cursor for cursor in cursors
      assert cache.get(cursor.path) is cursor for cursor in cursors

      cache.clearPath ['a', 'b']

      cleared = [c1, c2]
      uncleared = [c3, c4]
      assert cache.get(cursor.path) is undefined for cursor in cleared
      assert cache.get(cursor.path) is cursor for cursor in uncleared

    it 'should prune unnecessary nodes', ->
      c1 = path: ['a', 'b', 'c']
      cache.store c1

      assert.equal cache.root.size, 1
      assert.equal cache.root.get('a').size, 1
      assert.equal cache.root.get('a').get('b').size, 1
      assert.equal cache.root.get('a').get('b').get('c').size, 1
      assert.equal cache.size(), 3

      cache.clearPath ['a', 'b', 'c']

      assert.equal cache.root.size, 0
      assert.equal cache.size(), 0

  describe '#clearObject', ->

    it 'should clear the path to and all paths within an object', ->
      c1 = path: ['a']
      c2 = path: ['a', 'b']
      c3 = path: ['a', 'b', 'c']
      c4 = path: ['a', 'b', 'd']
      c5 = path: ['a', 'e']

      cursors = [c1, c2, c3, c4, c5]
      cache.store cursor for cursor in cursors
      assert.equal cache.get(cursor.path), cursor for cursor in cursors

      cache.clearObject ['a'], {b: {c: 1, d: 2, e: 3}}

      cleared = [c1, c2, c3, c4]
      uncleared = [c5]

      assert not cache.get(cursor.path)? for cursor in cleared
      assert.equal cache.get(cursor.path), cursor for cursor in uncleared


  describe '#spliceArray', ->

    it 'should clear a path to array and elements removed, shifting others', ->
      c1 = path: ['a']
      c2 = path: ['a', 'b']
      c3 = path: ['a', 'e']
      c4 = path: ['a', 'e', 0]
      c5 = path: ['a', 'e', 1]
      c6 = path: ['a', 'e', 2]

      cursors = [c1, c2, c3, c4, c5, c6]
      cache.store cursor for cursor in cursors
      assert cache.get(cursor.path) is cursor for cursor in cursors

      cache.spliceArray ['a', 'e'], 0, 1, 2

      cleared = [c1, c3, c4]
      assert cache.get(cursor.path) is undefined for cursor in cleared
      assert cache.get(['a', 'b']) is c2
      assert cache.get(['a', 'e', 2]) is c5
      assert cache.get(['a', 'e', 3]) is c6


  describe '#size', ->

    it 'should count nodes in cache tree', ->

      cache.store path: ['a', 'b', 'c']
      assert.equal cache.size(), 3

      cache.store path: ['a', 'b', 'd']
      assert.equal cache.size(), 4

      cache.store path: ['a', 'e', 1]
      assert.equal cache.size(), 6

      cache.store path: ['a', 'e', 2]
      assert.equal cache.size(), 7

