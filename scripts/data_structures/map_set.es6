module.exports = class MapSet {

  constructor() {
    this.map = new Map
  }

  get(key) {
    return this.map.get(key)
  }

  add(key, value) {
    let set = this.map.get(key)
    if (set == null) {
      set = new Set
      this.map.set(key, set)
    }

    return set.add(value)
  }

  delete(key, value) {
    if (arguments.length === 1) {
      return this.map.delete(key)
    } else {
      let set = this.map.get(key)
      if (set == null) {
        return false
      } else {
        let result = set.delete(value)
        if (set.size === 0) this.map.delete(key)
        return result
      }
    }
  }

  has(key, value) {
    if (arguments.length === 1) {
      return this.map.has(key)
    } else {
      let set = this.map.get(key)
      return !!set && set.has(value)
    }
  }

}
