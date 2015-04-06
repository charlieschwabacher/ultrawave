module.exports = class MapArray {

  constructor() {
    this.map = new Map
  }

  get(key) {
    return this.map.get(key)
  }

  push(key, value) {
    let arr = this.map.get(key)
    if (arr == null) {
      arr = []
      this.map.set(key, arr)
    }
    return arr.push(value)
  }
}
