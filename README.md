# Ultrawave

Ultrawave is a library enabling shared state through peer to peer connections over WebRTC data channels.  Ultrawave makes it easy to build things like real time collaborative editing, messaging, and games.  It works great with, but is not tied to, [React](//github.com/facebook/react).

To build an app with ultrawave, you connect a group of peers and provide an initial chunk of JSON serializable data - peers are able to read and write to the shared data through [cursors](//github.com/charlieschwabacher/subtree), with changes made by any peer showing up for everyone in the group.  Data is eventually consistant between peers, even in the face of lost, duplicated, or misordered messages.

There are some repos with example code available, as well as an abbreviated example at the end of this readme:
 - [a simple peer to peer messaging app](//github.com/charlieschwabacher/ultrawave-chat-example)
 - [a multi player chess game](//github.com/charlieschwabacher/ultrawave-chess-example)


### Installation

Grab the library from npm: `npm install ultrawave`


### Creating a new ultrawave

WebRTC allows direct communication between peers, but requires a server to form the initial connections.  You can run a simple websocket server for peering by creating an instance of UltrawaveServer

```javascript
const UltrawaveServer = require('ultrawave/server')
let server = new UltrawaveServer({port: 5000})
```

Then, in the browser, create an ultrawave and provide the url for your peering server.

```javascript
peer = new Ultrawave('ws://localhost:5000')
```


### Creating a peer group

Create a group by providing a group name, some initial data, and a callback to handle changes.  Whenever the data is updated, locally or by a peer, your callback will be passed a root cursor which it can use to read or write data.

```jsx
peer.create(group, data, (cursor) => {
  React.render(<Component cursor={cursor}>, el)
})
```
You can also join an existing group by name,
```jsx
peer.join(group, (cursor) => {
  React.render(<Component cursor={cursor}>, el)
})
```
...use joinOrCreate if you don't care which one you do,
```jsx
peer.joinOrCreate(group, data, (cursor) => {
  React.render(<Component cursor={cursor}>, el)
})
```
...or leave a group.
```javascript
peer.leave(group)
```


### Changes made by any peer are applied everywhere

Data in Ultrawave forms a tree structure where nodes are either arrays or objects.  In messages between peers, changes are represented as the path from the root to the node to be modified, a method, and arguments.  Available methods on objects are 'set', 'delete', and 'merge', and on arrays are 'set', 'delete', and 'splice' (and shortcuts based on splice: 'push', 'pop', 'shift' and 'unshift').

These changes are made through *cursors* - objects that wrap the path to a specific node, and allow reads and writes to that node and its subtree.  Every peer connects to every other peer in its group, and sends any changes made through its cursors to each of its peers.  For the full cursor api, see the [subtree](//github.com/charlieschwabacher/subtree) package.

Because messages can be lost or received out of order, [vector clocks](//en.wikipedia.org/wiki/Vector_clock) are used to detect missed messages and create an ordering for changes allowing the document state to be eventually consistant between peers.


### Example

This is an example of a simple chat app built with Ultrawave and React in 20 lines.  It creates a group with an empty array as initial data, then renders a react component when data changes.  The component is passed a cursor as a prop, from which it reads data to render the messages.  When the button is clicked, the component updates the data by pushing a new message onto the cursor causing it to be sent to each peer.

```jsx
const Chat = React.createClass({
  render: function() {
    const messages = this.props.cursor
    return <div>
      {messages.get().map((message) => <p>{message}</p>)}
      <input ref='input'/>
      <button
        onClick={() => {
          const input = refs.input.getDOMNode()
          messages.push(input.value)
          input.value = ''
        }}
      >send</button>
    </div>
  }
})

peer.joinOrCreate('chatroom', [], (cursor) => {
  React.render(<Chat cursor={cursor}/>, document.body)
})
```


### Considerations

Ultrawave is great if you want to easily build peer to peer apps, but here are a few cases in which it will not work well:

- Right now only Chrome and Firefox support WebRTC peer to peer connections.  Microsoft has announced planned support, but if you need your app to run in IE or Safari today, Ultrawave (and WebRTC in general) will not work for you.

- For users behind firewalls, the peer to peer connections used by WebRTC may be blocked - this can be worked around by proxying traffic between peers through a [TURN](//www.html5rocks.com/en/tutorials/webrtc/infrastructure/) server, but if you end up needing to use a central server anyways, WebSockets are likely to be a better choice.

- Ultrawave allows any peer to edit any part of the data tree and does not attempt to validate changes.  If you are building an app where trust between peers is an issue (for example a game where you are worried about cheating), ultrawave is not a good choice.  Ultrawave is built on a lower level messaging library [peergroup](//github.com/charlieschwabacher/peergroup), which might work better for you.


### About

Ultrawave was originally written for the [sinesaw](//github.com/charlieschwabacher/sinesaw) web audio DAW project.  It uses [peergroup](//github.com/charlieschwabacher/peergroup) for messaging over WebRTC data channels, and [subtree](//github.com/charlieschwabacher/subtree) for immutable data modeling with cursors.
