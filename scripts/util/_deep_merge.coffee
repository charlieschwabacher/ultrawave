isObject = (o) -> o? and toString.call(o) is '[object Object]'

module.exports = deepMerge = (src, data) ->

  dst = if Array.isArray src then [] else {}

  for key of src
    dst[key] = src[key]

  for key of data
    if isObject(data[key]) and isObject(src[key])
      dst[key] = deepMerge src[key], data[key]
    else
      dst[key] = data[key]

  dst
