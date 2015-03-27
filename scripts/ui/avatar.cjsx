React = require 'react'

module.exports = React.createClass

  displayName: 'avatar'

  propTypes:
    user: React.PropTypes.number.isRequired
    default: React.PropTypes.string

  getDefaultProps: ->
    default: 'retro'

  render: ->
    <img
      className='avatar'
      src={"//www.gravatar.com/avatar/#{@props.user}?d=#{@props.default}"}
    />
