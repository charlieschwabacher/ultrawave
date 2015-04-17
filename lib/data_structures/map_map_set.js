"use strict";

var _classCallCheck = function (instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } };

var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

module.exports = (function () {
  function MapMapSet() {
    _classCallCheck(this, MapMapSet);

    this.map = new Map();
  }

  _createClass(MapMapSet, [{
    key: "get",
    value: function get(key1, key2) {
      var map = this.map.get(key1);
      if (map != null) {
        return map.get(key2);
      }
    }
  }, {
    key: "add",
    value: function add(key1, key2, value) {
      var map = this.map.get(key1);
      if (map == null) {
        map = new Map();
        this.map.set(key1, map);
      }

      var set = map.get(key2);
      if (set == null) {
        set = new Set();
        map.set(key2, set);
      }

      return set.add(value);
    }
  }, {
    key: "delete",
    value: function _delete(key1, key2, value) {
      if (arguments.length === 1) {
        return this.map["delete"](key1);
      } else if (arguments.length === 2) {
        var map = this.map.get(key1);
        return map != null && map["delete"](key2);
      } else {
        var map = this.map.get(key1);
        var set = map && map.get(key2);
        return set != null && set["delete"](value);
      }
    }
  }, {
    key: "has",
    value: function has(key1, key2, value) {
      if (arguments.length === 1) {
        return this.map.has(key1);
      } else if (arguments.length === 2) {
        var map = this.map.get(key1);
        return map != null && map.has(key2);
      } else {
        var map = this.map.get(key1);
        var set = map && map.get(key2);
        return set != null && set.has(value);
      }
    }
  }]);

  return MapMapSet;
})();