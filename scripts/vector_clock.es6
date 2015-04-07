module.exports = class VectorClock {

  constructor(id, clock) {
    this.id = id

    if (arguments.length > 1) {
      if (!clock instanceof VectorClock) {
        clock = new VectorClock(clock.id, clock)
      }
      for (let key of clock.keys()) {
        this[key] = clock[key]
      }
    }

    this[this.id] = this[this.id] || 0
  }

  clone() {
    return new VectorClock(this.id, this)
  }

  keys() {
    return (for (key of Object.keys(this)) if (key !== 'id') key)
  }

  increment() {
    this[this.id] += 1
    return this
  }

  update(clock) {
    if (!clock instanceof VectorClock) {
      clock = new VectorClock(clock.id, clock)
    }

    for (let id of clock.keys()) {
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
    if (!clock instanceof VectorClock) {
      clock = new VectorClock(clock.id, clock)
    }

    let later = false
    let earlier = false
    for (let id of clock.keys()) {
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
