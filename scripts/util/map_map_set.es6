module.exports = class MapMapSet {

  constructor() {
    this.map = new Map
  }

  get(key1, key2) {
    const map = this.map.get(key1)
    if (map != null) {
      return map.get(key2)
    }
  }

  add(key1, key2, value) {
    const map = this.map.get(key)
    if (map == null) {
      map = new Map
      this.map.set(key1, map)
    }

    const set = map.get(key2)
    if (set == null) {
      set = new Set
      map.set(key2, set)
    }

    return set.add(value)
  }

  delete(key1, key2, value) {
    if (arguments.length === 1) {
      return this.map.delete(key1)
    } else if (arguments.length === 2) {
      const map = this.map.get(key1)
      return map != null && map.delete(key2)
    } else {
      const map = this.map.get(key1)
      const set = map && map.get(key2)
      return set != null && set.delete(value)
    }
  }

  has(key1, key2, value) {
    if (arguments.length === 1) {
      return this.map.has(key1)
    } else if (arguments.length === 2) {
      const map = this.map.get(key1)
      return map != null && map.has(key2)
    } else {
      const map = this.map.get(key1)
      const set = map && map.get(key2)
      return set != null && set.has(value)
    }
  }

}
