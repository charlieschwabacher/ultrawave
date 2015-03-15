React = require 'react/addons'
Avatar = require './avatar'
CSSTransitionGroup = React.addons.CSSTransitionGroup

module.exports = React.createClass

  displayName: 'Peers'

  propTypes:
    id: React.PropTypes.number.isRequired
    peers: React.PropTypes.arrayOf(React.PropTypes.number)

  render: ->
    <div className='peers'>
      <div className='user'>
        <div className='peer'>
          <Avatar user={@props.id}/>
          {@props.id} (you)
        </div>
        <small>
          connected to {@props.peers?.length or 0} peers
        </small>
      </div>
      <CSSTransitionGroup transitionName='fade'>
        {
          @props.peers.map (id) ->
            <div className='peer' key={id}>
              <Avatar user={id}/>
              {id}
            </div>
        }
      </CSSTransitionGroup>
    </div>
