module.exports = class MapMap {

  constructor() {
    this.map = new Map
  }

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

    return map.set(key2, value)
  }

  delete(key1, key2) {
    if (arguments.length === 1) {
      return this.map.delete(key1)
    } else {
      let map = this.map.get(key1)
      if (map == null) {
        return false
      } else {
        let result = map.delete(key2)
        if (map.size === 0) this.map.delete(key1)
        return result
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