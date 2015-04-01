// recursively call Object.freeze on an object and its keyerties

module.exports = function deepFreeze(object) {

  if (!object instanceof Object) return object

  for (let key in object) {
    if (!object.hasOwnProperty(key)) continue
    let value = object[key]

    if (value != null && typeof value === 'object' && !Object.isFrozen(value)) {
      deepFreeze(value)
    }
  }

  return Object.freeze(object)
}
