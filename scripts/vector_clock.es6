module.exports = class VectorClock {

  constructor(id, clock) {
    this.id = id

    if (arguments.length > 1) {
      if (!clock instanceof VectorClock) {
        clock = new VectorClock(clock.id, clock)
      }
      for (let key of Object.keys(clock)) {
        if (key === 'id') continue
        this[key] = clock[key]
      }
    }

    this[this.id] = this[this.id] || 0
  }

  clone() {
    return new VectorClock(this.id, this)
  }

  keys() {
    results = []
    for (let key of Object.keys(this)) {
      if (key === 'id') continue
      results.push(key)
    }
    return results
  }

  increment() {
    this[this.id] += 1
    return this
  }

  update(clock) {
    for (let key of Object.keys(clock)) {
      if (key === 'id') continue

      let tick = clock[key]
      let latest = this[key]

      if (latest) {
        this[key] = Math.max(latest, tick)
      } else {
        this[key] = tick
      }
    }
    return this
  }

  laterThan(clock) {
    let later = false
    let earlier = false
    for (let key of Object.keys(clock)) {
      if (key === 'id') continue

      if (this[key] < clock[key]) {
        earlier = true
      } else if (this[key] > clock[key]) {
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
