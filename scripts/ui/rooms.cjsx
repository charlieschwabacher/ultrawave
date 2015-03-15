React = require 'react/addons'
CSSTransitionGroup = React.addons.CSSTransitionGroup
Ultrawave = require '../ultrawave'


module.exports = React.createClass

  displayName: 'Rooms'

  propTypes:
    uw: React.PropTypes.instanceOf(Ultrawave).isRequired
    rooms: React.PropTypes.arrayOf(React.PropTypes.string).isRequired
    selectRoom: React.PropTypes.func.isRequired
    currentRoom: React.PropTypes.string

  render: ->
    uw = @props.uw
    rooms = @props.rooms

    <div className='rooms'>
      <CSSTransitionGroup transitionName='fade'>
        {
          rooms.map (room) =>
            <div
              className={
                'room' +
                (if room is @props.currentRoom then ' active' else '')
              }
              key={room}
              onClick={=> @props.selectRoom room}
            >
              {room}
              <div
                className='leave'
                onClick={
                  (e) =>
                    e.stopPropagation()
                    uw.leave room
                }
              >
                &#xd7;
              </div>
            </div>
        }
      </CSSTransitionGroup>
      <div
        className='room add-room'
        onClick={
          ->
            r = prompt 'Join room:'
            uw.join r if r
        }
      >
        +
      </div>
    </div>
