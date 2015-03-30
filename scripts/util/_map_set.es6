module.exports = class MapSet {

  constructor() {
    this.map = new Map
  }

  get(key) {
    this.map.get(key)
  }

  add(key, value) {
    let set = this.map.get(key)
    if (set == null) {
      set = new Set
      this.map.set(key, set)
    }

    set.add(value)
  }

  delete(key, value) {
    if (arguments.length === 1) {
      this.map.delete(key)
    } else {
      let set = this.map.get(key)
      if (set) {
        set.delete(value)
        if (set.size === 0) this.map.delete(key)
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