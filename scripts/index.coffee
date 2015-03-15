React = require 'react'
Ultrawave = require './ultrawave'
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

uw.on 'start', ->
  uw.join 'lobby'
  render()

uw.on 'peer', render
uw.on 'join', render
uw.on 'leave', render
uw.on 'message', addMessage
