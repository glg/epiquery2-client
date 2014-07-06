var EpiBufferingClient, EpiSimpleClient, guid, q,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

EpiBufferingClient = require('./epi-buffering-client');

guid = require('./guid');

q = require('q');

EpiSimpleClient = (function(_super) {
  __extends(EpiSimpleClient, _super);

  function EpiSimpleClient(url) {
    this.url = url;
    this.onerror = __bind(this.onerror, this);
    this.onendquery = __bind(this.onendquery, this);
    this.exec = __bind(this.exec, this);
    this.onrow = __bind(this.onrow, this);
    EpiSimpleClient.__super__.constructor.call(this, this.url);
    this.callbacks = {};
  }

  EpiSimpleClient.prototype.onrow = function(msg) {
    var row;
    row = {};
    msg.columns.forEach(function(column) {
      return row[column.name] = column.value;
    });
    return this.results[msg.queryId].currentResultSet.push(row);
  };

  EpiSimpleClient.prototype.exec = function(connectionName, template, data, callback) {
    var deferred, queryId;
    queryId = guid();
    deferred = q.defer();
    if (callback) {
      this.callbacks[queryId] = callback;
    } else {
      this.callbacks[queryId] = deferred;
    }
    this.query(connectionName, template, data, queryId);
    return deferred.promise;
  };

  EpiSimpleClient.prototype.onendquery = function(msg) {
    var callback;
    if (!(callback = this.callbacks[msg.queryId])) {
      return;
    }
    if (callback.promise) {
      callback.resolve(this.results[msg.queryId]);
    } else {
      callback(null, this.results[msg.queryId]);
    }
    return delete this.callbacks[msg.queryId];
  };

  EpiSimpleClient.prototype.onerror = function(msg) {
    var callback;
    if (!(callback = this.callbacks[msg.queryId])) {
      return;
    }
    if (callback.promise) {
      callback.reject(this.results[msg.queryId]);
    } else {
      callback(msg);
    }
    return delete this.callbacks[msg.queryId];
  };

  return EpiSimpleClient;

})(EpiBufferingClient);

module.exports = EpiSimpleClient;
