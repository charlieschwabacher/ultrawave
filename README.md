# Ultrawave

Ultrawave is small library for shared state using peer to peer messaging over WebRTC data channels.  Ultrawave makes it easy to build things like real time collaborative editing, communication, and games.  It works great with, but is not tied to, React.js.



## Usage


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

```javascript
peer.create(group, data, (cursor) => {
  React.render(<Component cursor={cursor}>, el)
})
```
You can also join an existing group by name.

```javascript
peer.join(group, (cursor) => {
  React.render(<Component cursor={cursor}>, el)
})
```
...or leave a group.

```javascript
peer.leave(group)
```


### Changes made by any peer are applied everywhere

Data in Ultrawave is represented as a 'document' - a tree structure where nodes are either arrays or objects.  Changes are represented as the path to the node to be modified, a method, and arguemnts.  Methods on objects are 'set', 'delete', and 'merge', and methods on arrays are 'set', 'delete', and 'splice' (and some shortcuts based on splice, 'push', 'pop', 'shift' and 'unshift').

A cursor is a pointer to one node at a specific path in the tree, and has methods to read and write to its subtree.  For example, this creates a simple chatroom

```javascript
const Chat = React.createClass({
  getInitialState: function() {
    return {message: ''}
  }
  render: function() {
    return (
      <div>
        {
          cursor.get('messages').map((message) =>
            <p>{message}</p>
          )
        }
        <input
          value={this.state.message}
          onChange={(e) => this.setState({message: e.target.value})}
        />
        <button
          onClick={() => {
            cursor.push('messages', this.state.message)
            this.setState({message: ''})
          }}
        />
      </div>
    )
  }
})

peer.create('chatroom', {messages: []}, (cursor) => {
  React.render(<Chat cursor={cursor}/>, document.body)
})
```

Every peer connects to all of the other peers in its group, and sends any changes made through its cursors to all member of its peer group.  Because it is difficult to synchronize clocks, and messages can be lost or received out of order or can be lost, [vector clocks](//en.wikipedia.org/wiki/Vector_clock) are used to create an ordering so that the document state will be eventually consistant across peers.

Under the hood, peering and messaging over RTC data channels is handled by the [peergroup]() package, and data modeling uses the [cursor](//github.com/charlieschwabacher/cursor) package.

