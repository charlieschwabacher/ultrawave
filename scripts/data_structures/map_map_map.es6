module.exports = class MapMapSet {

  constructor() {
    this.map = new Map
  }

  get(key1, key2, key3) {
    const map = this.map.get(key1)
    const map2 = map && map.get(key2)
    return map2 && map2.get(key2)
  }

  set(key1, key2, key3, value) {
    let map = this.map.get(key)
    if (map == null) {
      map = new Map
      this.map.set(key1, map)
    }

    let map2 = map.get(key2)
    if (map2 == null) {
      map2 = new Map
      map.set(key2, map2)
    }

    return map2.set(key3, value)
  }

  delete(key1, key2, key3) {
    if (arguments.length === 1) {
      return this.map.delete(key1)
    } else if (arguments.length === 2) {
      const map = this.map.get(key1)
      return map != null && map.delete(key2)
    } else {
      const map = this.map.get(key1)
      const map2 = map && map.get(key2)
      return map2 != null && map2.delete(value)
    }
  }

  has(key1, key2, key3) {
    if (arguments.length === 1) {
      return this.map.has(key1)
    } else if (arguments.length === 2) {
      const map = this.map.get(key1)
      return map != null && map.has(key2)
    } else {
      const map = this.map.get(key1)
      const map2 = map && map.get(key2)
      return map2 != null && map2.has(key3)
    }
  }

}
