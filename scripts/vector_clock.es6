module.exports = class VectorClock {

  constructor(id, clock) {
    this.id = id
    for (let key in clock) this[key] = clock[key]
    this[this.id] = this[this.id] || 0
  }

  clone() {
    return new VectorClock(this.id, this)
  }

  increment() {
    this[this.id] += 1
    return this
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
    }
    return this
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
    return this[id] >= tick
  }
}
