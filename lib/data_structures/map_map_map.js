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
    value: function get(key1, key2, key3) {
      var map = this.map.get(key1);
      var map2 = map && map.get(key2);
      return map2 && map2.get(key3);
    }
  }, {
    key: "set",
    value: function set(key1, key2, key3, value) {
      var map = this.map.get(key1);
      if (map == null) {
        map = new Map();
        this.map.set(key1, map);
      }

      var map2 = map.get(key2);
      if (map2 == null) {
        map2 = new Map();
        map.set(key2, map2);
      }

      return map2.set(key3, value);
    }
  }, {
    key: "delete",
    value: function _delete(key1, key2, key3) {
      if (arguments.length === 1) {
        return this.map["delete"](key1);
      } else if (arguments.length === 2) {
        var map = this.map.get(key1);
        var result = map && map["delete"](key2);
        if (map.size === 0) this.map["delete"](key1);
        return result;
      } else {
        var map = this.map.get(key1);
        var map2 = map && map.get(key2);
        var result = map2 && map2["delete"](key3);
        if (map2.size === 0) map["delete"](key2);
        if (map.size === 0) this.map["delete"](key1);
        return result;
      }
    }
  }, {
    key: "has",
    value: function has(key1, key2, key3) {
      if (arguments.length === 1) {
        return this.map.has(key1);
      } else if (arguments.length === 2) {
        var map = this.map.get(key1);
        return map != null && map.has(key2);
      } else {
        var map = this.map.get(key1);
        var map2 = map && map.get(key2);
        return map2 != null && map2.has(key3);
      }
    }
  }]);

  return MapMapSet;
})();