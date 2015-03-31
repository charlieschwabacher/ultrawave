module.exports = function debounce(wait, func) {
  let timeout, args, context, timestamp

  const later = () => {
    const last = Date.now() - timestamp

    if (last < wait && last > 0) {
      timeout = setTimeout(later, wait - last)
    } else {
      func.apply(context, args)
      context = args = timeout = null
    }
  }

  return function() {
    context = this
    args = arguments
    timestamp = Date.now()
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)
  }
}