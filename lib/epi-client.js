var EpiClient, EventEmitter, WebSocket, log, _,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

EventEmitter = require('events').EventEmitter;

_ = require('underscore');

log = require('simplog');

WebSocket = require('hunting-websocket');

EpiClient = (function(_super) {
  __extends(EpiClient, _super);

  function EpiClient(url) {
    this.url = url;
    this.onsend = __bind(this.onsend, this);
    this.onbeginrowset = __bind(this.onbeginrowset, this);
    this.onerror = __bind(this.onerror, this);
    this.onendquery = __bind(this.onendquery, this);
    this.onbeginquery = __bind(this.onbeginquery, this);
    this.onrow = __bind(this.onrow, this);
    this.onClose = __bind(this.onClose, this);
    this.onMessage = __bind(this.onMessage, this);
    this.query = __bind(this.query, this);
    this.connect = __bind(this.connect, this);
    this.connect();
  }

  EpiClient.prototype.connect = function() {
    if (!_.isArray(this.url)) {
      this.url = [this.url];
    }
    this.ws = new WebSocket(this.url);
    this.queryId = 0;
    this.ws.onmessage = this.onMessage;
    this.ws.onclose = this.onClose;
    this.ws.onopen = function() {
      return log.debug("Epiclient connection opened");
    };
    this.ws.onerror = function(err) {
      return log.error("EpiClient socket error: ", err);
    };
    return this.ws.onsend = this.onsend;
  };

  EpiClient.prototype.query = function(connectionName, template, data, queryId) {
    var req;
    if (queryId == null) {
      queryId = null;
    }
    req = {
      templateName: template,
      connectionName: connectionName,
      data: data
    };
    req.queryId = null || queryId;
    if (data) {
      req.closeOnEnd = data.closeOnEnd;
    }
    this.ws.forceClose = req.closeOnEnd;
    log.debug("executing query: " + template + " data:" + (JSON.stringify(data)));
    return this.ws.send(JSON.stringify(req));
  };

  EpiClient.prototype.onMessage = function(message) {
    var handler;
    if ((message.type != null) && (message.type = 'message')) {
      message = message.data;
    }
    if (typeof message === 'string') {
      message = JSON.parse(message);
    }
    handler = this['on' + message.message];
    if (handler) {
      return handler(message);
    }
  };

  EpiClient.prototype.onClose = function() {
    return this.emit('close');
  };

  EpiClient.prototype.onrow = function(msg) {
    return this.emit('row', msg);
  };

  EpiClient.prototype.onbeginquery = function(msg) {
    return this.emit('beginquery', msg);
  };

  EpiClient.prototype.onendquery = function(msg) {
    return this.emit('endquery', msg);
  };

  EpiClient.prototype.onerror = function(msg) {
    return this.emit('error', msg);
  };

  EpiClient.prototype.onbeginrowset = function(msg) {
    return this.emit('beginrowset', msg);
  };

  EpiClient.prototype.onsend = function(msg) {
    return this.emit('send', msg);
  };

  return EpiClient;

})(EventEmitter);

module.exports = EpiClient;
