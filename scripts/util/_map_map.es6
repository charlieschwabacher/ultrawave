module.exports = class MapMap {

  constructor() {
    @map = new Map

  get(key1, key2) {
    if (arguments.length === 1) {
      return this.map.get(key1)
    } else {
      let map = this.map.get(key1)
      return map && map.get(key2)
    }
  }

  set(key1, key2, value) {
    let map = this.map.get(key1)
    if (map == null) {
      map = new Map
      this.map.set(key1, map)
    }

    map.set(key2, value)
  }

  delete(key1, key2) {
    if (arguments.length === 1) {
      this.map.delete(key1)
    } else {
      let map = this.map.get(key1)
      if (map) {
        map.delete(key2)
        if (map.size === 0) this.map.delete(key1)
      }
    }
  }

  has(key1, key2) {
    if (arguments.length === 1) {
      return this.map.has(key1)
    } else {
      let map = this.map.get(key1)
      return !!map && map.has(key2)
    }
  }
}