// Generated by CoffeeScript 1.7.1
var Storage, co, oa, oo, _,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

_ = require('lodash');

oo = ko.observable;

oa = ko.observableArray;

co = ko.computed;

Storage = (function() {
  Storage.create_socket = function(name_space, io) {
    var socket;
    socket = io.connect('/socket_api_storage_' + name_space);
    return socket;
  };

  function Storage(options) {
    if (options == null) {
      options = {};
    }
    this.update = __bind(this.update, this);
    this.set = __bind(this.set, this);
    this.get = __bind(this.get, this);
    this._end_point = __bind(this._end_point, this);
    this.socket = options.socket ? options.socket : Storage.create_socket('', io);
    this.name_space = options.name_space || '';
    this.storage = oo(false);
  }

  Storage.prototype._end_point = function(name) {
    return name;
  };

  Storage.prototype.get = function(cb) {
    return this.socket.emit(this._end_point('get'), null, (function(_this) {
      return function(err, d) {
        _this.storage(d);
        if (cb != null) {
          return cb(d);
        }
      };
    })(this));
  };

  Storage.prototype.set = function(data, cb) {
    return this.socket.emit(this._end_point('set'), data, (function(_this) {
      return function(err) {
        if (cb != null) {
          return cb(err);
        }
      };
    })(this));
  };

  Storage.prototype.update = function(cb) {
    cb(this.storage());
    return this.set(this.storage(), (function(_this) {
      return function(err) {};
    })(this));
  };

  return Storage;

})();

module.exports = Storage;
