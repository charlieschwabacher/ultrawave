// recursively call Object.freeze on an object and its properties

module.exports = function deepFreeze(o) {

  if (!o instanceof Object) return o

  for (prop of Object.getOwnPropertyNames(o)) {
    if (
      (o[prop] != null) &&
      (typeof o[prop] === 'object' || typeof o[prop] === 'function') &&
      !(o[prop] instanceof Float32Array) &&
      !(Object.isFrozen(o[prop]))
    ) deepFreeze(o[prop])
  }

  return Object.freeze(o)

}