# Ultrawave

Ultrawave is a library enabling shared state through direct communication between peers over WebRTC data channels.  Ultrawave makes it easy to build things like real time collaborative editing, messaging, and games.  It works great with, but is not tied to, [React](//github.com/facebook/react).

There are some repos with example code available - see [ultrawave-chat-example](//github.com/charlieschwabacher/ultrawave-chat-example) for a simple peer to peer chat app, or [ultrawave-chess-example](//github.com/charlieschwabacher/ultrawave-chess-example) for a chess game.  Or, continue reading for some abbreviated example code at the end of the readme.


### Installation

Grab the library from npm: `npm install ultrawave`


### Creating a new ultrawave

WebRTC allows direct communication between peers, but requires a server to form the initial connections.  You can run a simple websocket server for peering by creating an instance of UltrawaveServer

```javascript
const UltrawaveServer = require('ultrawave/server')
let server = new UltrawaveServer(5000)
```

Then, in the browser, create an ultrawave and provide the url for your peering server.

```javascript
peer = new Ultrawave('ws://localhost:5000')
```


### Creating a peer group

Create a group by providing a group name, some initial data, and a callback to handle changes.  Whenever the data is updated, locally or by a peer, your callback will be passed a root *'cursor'* which it can use to read or write data.

```jsx
peer.create(group, data, (cursor) => {
  React.render(<Component cursor={cursor}>, el)
})
```
You can also join an existing group by name.

```jsx
peer.join(group, (cursor) => {
  React.render(<Component cursor={cursor}>, el)
})
```
...or leave a group.

```javascript
peer.leave(group)
```


### Changes made by any peer are applied everywhere

Data in Ultrawave is represented as a 'document' - a tree structure where nodes are either arrays or objects.  Changes are represented as the path to the node to be modified, a method, and arguemnts.  Methods on objects are 'set', 'delete', and 'merge', and on arrays are 'set', 'delete', and 'splice' (and shortcuts based on splice: 'push', 'pop', 'shift' and 'unshift').

Changes are made through 'cursors' - objects that wrap the path to a specific node, and provide methods to read and write to that node and its subtree.  Every peer connects to every other peers in its group, and sends any changes made through its cursors to each of its peers.  For the full cursor api, see the [subtree](//github.com/charlieschwabacher/subtree) package.

Because messages can be lost or received out of order, [vector clocks](//en.wikipedia.org/wiki/Vector_clock) are used to create an ordering for changes, so that the document state will be eventually consistant between peers.


### Example

Here is an example of a simple chat app built with Ultrawave - it initializes the data with an array as the root node, and renders a react component when data changes.  The component is passed a cursor as a prop, from which it reads data to render the messages.  When the button is clicked, the component updates data by pushing a new message onto the cursor (causing the message to be sent to each peer).

```jsx
const Chat = React.createClass({
  render: function() {
    const messages = this.props.cursor.get()
    return (
      <div>
        {messages.map((message) => <p>{message}</p>)}
        <input ref='input'/>
        <button
          onClick={() => {
            const input = refs.input.getDOMNode()
            cursor.push(input.value)
            input.value = ''
          }}
        >send</button>
      </div>
    )
  }
})

peer.create('chatroom', [], (cursor) => {
  React.render(<Chat cursor={cursor}/>, document.body)
})
```


### About

Ultrawave was originally written for the [sinesaw](//github.com/charlieschwbacher/sinesaw) web audio DAW project.  It uses [peergroup](//github.com/charlieschwabacher/peergroup) for messaging over WebRTC data channels, and [subtree](//github.com/charlieschwabacher/subtree) for immutable data modeling with cursors.
