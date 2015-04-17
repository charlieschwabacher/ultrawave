"use strict";

var _classCallCheck = function (instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } };

var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

module.exports = (function () {
  function MapArray() {
    _classCallCheck(this, MapArray);

    this.map = new Map();
  }

  _createClass(MapArray, [{
    key: "get",
    value: function get(key) {
      return this.map.get(key);
    }
  }, {
    key: "push",
    value: function push(key, value) {
      var arr = this.map.get(key);
      if (arr == null) {
        arr = [];
        this.map.set(key, arr);
      }
      return arr.push(value);
    }
  }]);

  return MapArray;
})();