# recursively call Object.freeze on an object and its properties

module.exports = deepFreeze = (o) ->

  return o unless o instanceof Object

  for prop in Object.getOwnPropertyNames o
    if (
      o.hasOwnProperty(prop) and
      o[prop]? and
      (typeof o[prop] is 'object' or typeof o[prop] is 'function') and
      not o[prop] instanceof Float32Array and
      not Object.isFrozen o[prop]
    )
      deepFreeze o[prop]

  Object.freeze o
