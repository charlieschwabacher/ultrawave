const Ultrawave = require('./ultrawave')
const Cursor = require('./cursor')


module.exports = class Wormhole {

  constructor(url) {
    this.ultrawave = new Ultrawave(url)
  }

  create(room, data, cb) {
    this.ultrawave.create(
      room,
      () => {

      },
      () => {

      }
    )
  }

  join(room, cb) {

  }

}
