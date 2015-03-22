assert = require 'assert'
CursorCache = require '../scripts/util/cursor_cache'



describe 'cache', ->

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


  describe '#clearPath', ->


  describe '#clearObject', ->


  describe '#spliceArray', ->


  describe '#size', ->

    it 'should count nodes in cache tree', ->

      cache.store path: ['a', 'b', 'c']
      console.log "size is #{cache.size()}"
      assert cache.size() is 4

      cache.store path: ['a', 'b', 'd']
      console.log "size is #{cache.size()}"
      assert cache.size() is 5

      cache.store path: ['a', 'e', 1]
      assert cache.size() is 7

      cache.store path: ['a', 'e', 2]
      assert cache.size is 8
