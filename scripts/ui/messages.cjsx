React = require 'react/addons'
MessageForm = require './message_form'
Avatar = require './avatar'
CSSTransitionGroup = React.addons.CSSTransitionGroup

module.exports = React.createClass

  displayName: 'Messages'

  propTypes:
    messages: React.PropTypes.arrayOf(React.PropTypes.array)
    sendMessage: React.PropTypes.func.isRequired

  render: ->
    setTimeout =>
      @refs.list.getDOMNode().scrollTop = Infinity

    <div className='messages'>
      <div className='message-list' ref='list'>
        {
          @props.messages?.map ([id, message], i) ->
            <div className='message' key={i}>
              <Avatar user={id}/>
              <strong>{id}</strong>
              {message}
            </div>
        }
      </div>
      <MessageForm sendMessage={@props.sendMessage}/>
    </div>
