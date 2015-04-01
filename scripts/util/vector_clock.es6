const MapSet = require('./map_set')


const missingSymbol = Symbol()


module.exports = class VectorClock {

  constructor(id, clock) {
    this.id = id
    this[missingSymbol] = new MapSet
    for (let key in clock) this[key] = clock[key]
    this[this.id] = this[this.id] || 0
  }

  increment() {
    return this[this.id] += 1
  }

  update(clock) {
    for (let id in clock) {
      let tick = clock[id]
      let latest = this[id]
      id = parseInt(id)

      if (latest) {
        this[id] = Math.max(latest, tick)
      } else {
        this[id] = tick
      }

      // keep track of missing updates
      this[missingSymbol].delete(id, tick)
      if (tick - (latest || 0) > 1) {
        for (let i = latest + 1; i < tick; i++) {
          this[missingSymbol].add(id, i)
        }
      }
    }
  }

  laterThan(clock) {
    let later = false
    let earlier = false
    for (let id in clock) {
      if (this[id] < clock[id]) {
        earlier = true
      } else if (this[id] > clock[id]) {
        later = true
      }
    }

    if (later && !earlier) {
      return true
    }
    else if (earlier && !later) {
      return false
    }
    else {
      return this.id < clock.id
    }
  }

  applied(id, tick) {
    return this[id] >= tick && !this[missingSymbol].has(id, tick)
  }
}