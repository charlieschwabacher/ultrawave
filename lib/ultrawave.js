'use strict';

var _slicedToArray = function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i['return']) _i['return'](); } finally { if (_d) throw _e; } } return _arr; } else { throw new TypeError('Invalid attempt to destructure non-iterable instance'); } };

var _classCallCheck = function (instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError('Cannot call a class as a function'); } };

var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ('value' in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

var PeerGroup = require('peergroup');
var Subtree = require('subtree');
var MapMapMap = require('./data_structures/map_map_map');
var MapMapSet = require('./data_structures/map_map_set');
var MapArray = require('./data_structures/map_array');
var VectorClock = require('./vector_clock');

var interval = 200;

module.exports = (function () {
  function Ultrawave(url) {
    var _this = this;

    _classCallCheck(this, Ultrawave);

    this.handles = new Map();
    this.clocks = new Map();
    this.changes = new MapArray(); // arrays of changes [data, clock, method, args]
    this.timeouts = new MapMapMap();
    this.peerGroup = new PeerGroup(url);

    // wait for id to be assigned by server before binding to other events

    this.peerGroup.ready.then(function (id) {

      _this.id = id;

      // add peers to clock immediately

      _this.peerGroup.on(_this.peerGroup.events.peer, function (group, id) {
        var clock = _this.clocks.get(group);
        if (clock != null) {
          clock.touch(id);
        }
      });

      // respond to requests from peers

      _this.peerGroup.on('request document', function (group, id) {
        var data = _this.handles.get(group).data();
        var clock = _this.clocks.get(group);
        _this.peerGroup.sendTo(group, id, 'document', { clock: clock, data: data });
      });

      _this.peerGroup.on('request changes', function (group, id, latest) {
        latest = new VectorClock(latest);
        var changes = _this.changes.get(group);
        for (var i = changes.length - 1; i >= 0; i -= 1) {
          var _changes$i = _slicedToArray(changes[i], 4);

          var clock = _changes$i[1];
          var method = _changes$i[2];
          var args = _changes$i[3];

          if (latest.laterThan(clock)) return;
          if (clock.id === _this.id) {
            _this.peerGroup.sendTo(group, id, method, { clock: clock, args: args });
          }
        }
      });

      _this.peerGroup.on('request sync', function (group, id, _ref) {
        var author = _ref.author;
        var tick = _ref.tick;

        for (var i = changes.length - 1; i >= 0; i -= 1) {
          var _changes$i2 = _slicedToArray(changes[i], 3);

          var clock = _changes$i2[0];
          var method = _changes$i2[1];
          var args = _changes$i2[2];

          if (clock.id === author && clock[author] == tick) {
            _this.peerGroup.sendTo(group, id, method, { clock: clock, args: args });
            break;
          }
        }
      });

      // apply changes from peers

      var methods = ['set', 'delete', 'merge', 'splice'];
      methods.forEach(function (method) {
        _this.peerGroup.on(method, function (group, id, _ref2) {
          var clock = _ref2.clock;
          var args = _ref2.args;

          clock = new VectorClock(clock);
          _this._clearTimeoutFor(group, clock);
          _this._syncMissingChangesFor(id, group, clock);
          _this._applyRemoteChange(group, clock, method, args);
          _this._updateClock(group, clock);
        });
      });
    });
  }

  _createClass(Ultrawave, [{
    key: '_clearTimeoutFor',
    value: function _clearTimeoutFor(group, clock) {
      var author = clock.id;
      var tick = clock[author];
      var pendingTimeout = this.timeouts.get(group, author, tick);
      if (pendingTimeout != null) {
        clearTimeout(pendingTimeout);
        this.timeouts['delete'](group, author, tick);
      }
    }
  }, {
    key: '_syncMissingChangesFor',
    value: function _syncMissingChangesFor(sender, group, clock) {
      var _this2 = this;

      // compare clock to the current clock to identify any missing messages

      var author = clock.id;

      var _loop = function (id) {
        var tick = clock[id];
        var latest = author[id];

        if (tick - (latest || 0) > 1) {
          var _loop2 = function (i) {

            var requestSync = function requestSync() {
              // if we are still connected to the author of the change, request
              // the change from them directly, otherwise request the change from
              // the sender
              if (_this2.peerGroup.peers(group).has(author)) {
                var _peer = author;
              } else {
                var _peer2 = sender;
              }

              _this2.peerGroup.sendTo(group, peer, 'request sync', {
                author: author,
                tick: i
              });

              setSyncTimeout();
            };

            var setSyncTimeout = function setSyncTimeout() {
              var timeout = setTimeout(requestSync, interval);
              _this2.timeouts.set(group, author, tick, timeout);
            };

            setSyncTimeout();
          };

          for (var i = latest + 1; i < tick; i++) {
            _loop2(i);
          }
        }
      };

      for (var id in clock) {
        _loop(id);
      }
    }
  }, {
    key: '_updateClock',
    value: function _updateClock(group, clock) {
      this.clocks.get(group).update(clock);
    }
  }, {
    key: '_applyRemoteChange',
    value: function _applyRemoteChange(group, clock, method, args) {
      var changes = this.changes.get(group);
      var handle = this.handles.get(group);

      // if the change is in order, apply it right away and return
      if (clock.laterThan(this.clocks.get(group))) {
        handle[method].apply(null, args);
        changes.push([handle.data(), clock, method, args]);
        return;
      }

      // find the most recent change earlier than than the incoming change,
      // unless we find that the incoming change has already been applied, in
      // which case we can return without bothering to apply it again
      var index = undefined;
      var author = clock.id;
      for (index = changes.length - 1; index >= 0; index -= 1) {
        var c = changes[index][1];
        if (c.id === author && clock[author] == c[author]) {
          return;
        }if (clock.laterThan(c)) break;
      }

      // rewind the data
      handle.set([], changes[index][0]);

      // apply the incoming change and splice it in place
      handle[method].apply(null, args);
      changes.splice(index + 1, 0, [handle.data(), clock, method, args]);

      // replay changes after the incoming change
      for (index = index + 2; index < changes.length; index += 1) {
        var _changes$index = _slicedToArray(changes[index], 4);

        var _method = _changes$index[2];
        var _args = _changes$index[3];

        handle[_method].apply(null, _args);
      }
    }
  }, {
    key: '_startCursor',
    value: function _startCursor(group, initialData, cb) {
      var _this3 = this;

      var clock = this.clocks.get(group);

      var changes = [];
      this.changes.map.set(group, changes);

      var handle = Subtree.create(initialData, function (root, newChanges) {
        var data = root.get();
        var _iteratorNormalCompletion = true;
        var _didIteratorError = false;
        var _iteratorError = undefined;

        try {
          for (var _iterator = newChanges[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
            var change = _step.value;

            var _change = _slicedToArray(change, 2);

            var method = _change[0];
            var args = _change[1];

            clock.increment();
            var newClock = clock.clone();
            changes.push([data, newClock, method, args]);
            _this3.peerGroup.send(group, method, { clock: newClock, args: args });
          }
        } catch (err) {
          _didIteratorError = true;
          _iteratorError = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion && _iterator['return']) {
              _iterator['return']();
            }
          } finally {
            if (_didIteratorError) {
              throw _iteratorError;
            }
          }
        }

        cb(root, changes);
      });
      this.handles.set(group, handle);

      return handle;
    }
  }, {
    key: 'create',
    value: function create(group, initialData, cb) {
      var _this4 = this;

      return new Promise(function (resolve, reject) {
        _this4.peerGroup.ready.then(function (id) {
          _this4.peerGroup.create(group).then(function () {
            _this4.clocks.set(group, new VectorClock({ id: id }));
            resolve(_this4._startCursor(group, initialData, cb));
          })['catch'](reject);
        });
      });
    }
  }, {
    key: 'join',
    value: function join(group, cb) {
      var _this5 = this;

      var events = this.peerGroup.events;

      return new Promise(function (resolve, reject) {
        _this5.peerGroup.ready.then(function (id) {
          _this5.peerGroup.join(group).then(function () {
            _this5.clocks.set(group, new VectorClock({ id: id }));

            // request the current document state from the first peer we form a
            // connection to, then send 'request changes' to each new peer
            // requesting changes they have authored after that clock.
            var docRequestCandidates = [];
            var docRequestTimeout = undefined;
            var changeRequestCandidates = undefined;
            var documentClock = undefined;

            var requestDocumentRetry = (function (_requestDocumentRetry) {
              function requestDocumentRetry() {
                return _requestDocumentRetry.apply(this, arguments);
              }

              requestDocumentRetry.toString = function () {
                return _requestDocumentRetry.toString();
              };

              return requestDocumentRetry;
            })(function () {
              if (docRequestCandidates.length > 0) {
                var _peer3 = docRequestCandidates.shift();
                _this5.peerGroup.sendTo(group, _peer3, 'request document');
              }

              docRequestTimeout = setTimeout(requestDocumentRetry, interval);
            });

            var onPeer = (function (_onPeer) {
              function onPeer(_x, _x2) {
                return _onPeer.apply(this, arguments);
              }

              onPeer.toString = function () {
                return _onPeer.toString();
              };

              return onPeer;
            })(function (subjectGroup, id) {
              if (subjectGroup !== group) return;

              if (docRequestTimeout == null) {

                // request the document immediately from the first peer

                _this5.peerGroup.sendTo(group, id, 'request document');
                docRequestTimeout = setTimeout(requestDocumentRetry, interval);
              } else if (documentClock == null) {

                // if the document has not been received, keep track of peers in
                // case we need to request the document from them

                docRequestCandidates.push(id);
              } else if (changeRequestCandidates.has(id)) {

                // once the document has been recevied, request changes from
                // peers as we connect to them

                _this5.peerGroup.send(group, id, 'request changes', documentClock);
                changeRequestCandidates['delete'](id);

                if (changeRequestCandidates.size === 0) {
                  _this5.peerGroup.off(events.peer, onPeer);
                }
              }
            });

            var onDocument = (function (_onDocument) {
              function onDocument(_x3, _x4, _x5) {
                return _onDocument.apply(this, arguments);
              }

              onDocument.toString = function () {
                return _onDocument.toString();
              };

              return onDocument;
            })(function (subjectGroup, id, _ref3) {
              var clock = _ref3.clock;
              var data = _ref3.data;

              if (subjectGroup !== group) return;
              _this5.peerGroup.off(events.document, onDocument);
              clearTimeout(docRequestTimeout);

              clock = new VectorClock(clock);
              _this5._updateClock(group, clock);

              // request changes from all group members
              changeRequestCandidates = new Set(clock.keys());
              changeRequestCandidates['delete'](clock.id);
              var _iteratorNormalCompletion2 = true;
              var _didIteratorError2 = false;
              var _iteratorError2 = undefined;

              try {
                for (var _iterator2 = _this5.peerGroup.peers(group)[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
                  var _peer4 = _step2.value;

                  if (changeRequestCandidates['delete'](_peer4)) {
                    _this5.peerGroup.send(group, 'request changes', clock);
                  }
                }
              } catch (err) {
                _didIteratorError2 = true;
                _iteratorError2 = err;
              } finally {
                try {
                  if (!_iteratorNormalCompletion2 && _iterator2['return']) {
                    _iterator2['return']();
                  }
                } finally {
                  if (_didIteratorError2) {
                    throw _iteratorError2;
                  }
                }
              }

              resolve(_this5._startCursor(group, data, cb));
            });

            _this5.peerGroup.on(events.peer, onPeer);
            _this5.peerGroup.on('document', onDocument);
          })['catch'](reject);
        });
      });
    }
  }, {
    key: 'leave',
    value: function leave(group) {
      this.peerGroup.leave(group);
      var _iteratorNormalCompletion3 = true;
      var _didIteratorError3 = false;
      var _iteratorError3 = undefined;

      try {
        for (var _iterator3 = this.timeouts.get(group).values()[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {
          var timeout = _step3.value;

          clearTimeout(timeout);
        }
      } catch (err) {
        _didIteratorError3 = true;
        _iteratorError3 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion3 && _iterator3['return']) {
            _iterator3['return']();
          }
        } finally {
          if (_didIteratorError3) {
            throw _iteratorError3;
          }
        }
      }

      this.handles['delete'](group);
      this.clocks['delete'](group);
      this.changes['delete'](group);
      this.timeouts['delete'](group);
    }
  }, {
    key: 'close',
    value: function close() {
      this.peerGroup.close();
    }
  }]);

  return Ultrawave;
})();