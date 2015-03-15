React = require 'react'
Rooms = require './rooms'
Messages = require './messages'
Peers = require './peers'
Ultrawave = require '../ultrawave'
MapArray = require '../util/map_array'


arrayFrom = (iterator) ->
  arr = []
  if iterator?
    {value, done} = iterator.next()
    while not done
      arr.push value
      {value, done} = iterator.next()
  arr


module.exports = React.createClass

  displayName: 'App'

  propTypes:
    uw: React.PropTypes.instanceOf(Ultrawave).isRequired
    messages: React.PropTypes.instanceOf(MapArray).isRequired
    addMessage: React.PropTypes.func.isRequired

  getInitialState: ->
    currentRoom: 'lobby'

  sendMessage: (message) ->
    return unless message.length > 0
    @props.uw.send @state.currentRoom, 'message', message
    @props.addMessage @state.currentRoom, @props.uw.id, message

  render: ->
    uw = @props.uw
    room = @state.currentRoom if uw.rooms.has @state.currentRoom
    messages = @props.messages.get room
    rooms = arrayFrom uw.rooms.values()
    peers = arrayFrom uw.connections.get(room)?.keys()

    <div className='app'>
      <div className='header'>
        <div className='title'>ultrawave</div>
        <Rooms
          uw={uw}
          currentRoom={room}
          rooms={rooms}
          selectRoom={(currentRoom) => @setState {currentRoom}}
        />
      </div>
      {
        if room
          <div className='main'>
            <Peers id={uw.id} peers={peers}/>
            <Messages
              messages={messages}
              sendMessage={@sendMessage}
            />
          </div>
        else
          <div className='loading'>Click the plus above to join a room</div>
      }
    </div>
