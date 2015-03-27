React = require 'react'
Ultrawave = require './util/ultrawave'
App = require './ui/app'
MapArray = require './util/map_array'

if process.env.NODE_ENV is 'development'
  require('build-status').client()
  window.React = React


window.messages = new MapArray

addMessage = (room, id, message) ->
  messages.push room, [id, message]
  render()

render = ->
  React.render(
    React.createElement(App, {uw, messages, addMessage}),
    document.body
  )


window.uw = new Ultrawave 'ws://localhost:3002'

uw.on uw.events.start, -> uw.joinOrCreate 'lobby'
uw.on uw.events.peer, render
uw.on uw.events.join, render
uw.on uw.events.leave, render
uw.on 'message', addMessage
