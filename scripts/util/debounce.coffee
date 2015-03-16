module.exports = (wait, func) ->
  timeout = args = context = timestamp = null

  later = ->
    last = Date.now() - timestamp

    if last < wait and last > 0
      timeout = setTimeout later, wait - last
    else
      timeout = null
      result = func.apply(context, args);
      context = args = null unless timeout

  ->
    context = this
    args = arguments
    timestamp = Date.now()
    clearTimeout timeout
    timeout = setTimeout later, wait
