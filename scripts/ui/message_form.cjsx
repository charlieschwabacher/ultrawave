React = require 'react'

module.exports = React.createClass

  displayName: 'MessageForm'

  propTypes:
    sendMessage: React.PropTypes.func.isRequired

  sendMessage: (e) ->
    e.preventDefault()
    input = @refs.input.getDOMNode()
    @props.sendMessage input.value
    input.value = ''

  render: ->
    <form
      className='message-form'
      onSubmit={@sendMessage}
    >
      <input type='text' ref='input'/>
      <input type='submit' value='send'/>
    </form>
