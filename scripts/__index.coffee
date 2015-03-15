# create peer connections

configuration = iceServers: [url: 'stun:stun.l.google.com:19302']

p1 = new webkitRTCPeerConnection configuration
p2 = new webkitRTCPeerConnection configuration


# listen for ice candidates

p1.addEventListener 'icecandidate', (e) ->
  p2.addIceCandidate e.candidate if e.candidate?

p2.addEventListener 'icecandidate', (e) ->
  p1.addIceCandidate e.candidate if e.candidate?


# create / listen for data channels

dc1 = p1.createDataChannel 'dc1'

dc1.addEventListener 'open', ->
  console.log 'data channel opened on 1'

p2.addEventListener 'datachannel', (e) ->
  console.log 'data channel opened on 2'


# exchange offer / answer

p1.createOffer (offer) ->
  p1.setLocalDescription offer
  p2.setRemoteDescription offer

  p2.createAnswer (answer) ->
    p2.setLocalDescription answer
    p1.setRemoteDescription answer
