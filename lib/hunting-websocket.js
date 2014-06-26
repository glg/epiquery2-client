var HuntingWebsocket, ReconnectingWebSocket, WebSocket, log;

log = require('simplog');

ReconnectingWebSocket = require('./reconnecting-websocket');

WebSocket = WebSocket || require('ws');

HuntingWebsocket = (function() {
  function HuntingWebsocket(urls) {
    var openAtAll, socket, url, _i, _len, _ref;
    this.urls = urls;
    openAtAll = false;
    this.lastSocket = void 0;
    this.sockets = [];
    _ref = this.urls;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      url = _ref[_i];
      socket = new ReconnectingWebSocket(url);
      this.sockets.push(socket);
      socket.onmessage = (function(_this) {
        return function(evt) {
          return _this.onmessage(evt);
        };
      })(this);
      socket.onerror = (function(_this) {
        return function(err) {
          return _this.onerror(err);
        };
      })(this);
      socket.onopen = (function(_this) {
        return function(evt) {
          if (!openAtAll) {
            openAtAll = true;
            return _this.onopen(evt);
          }
        };
      })(this);
      socket.onreconnect = (function(_this) {
        return function(evt) {
          return _this.onreconnect(evt);
        };
      })(this);
    }
    this.forceclose = false;
  }

  HuntingWebsocket.prototype.send = function(data) {
    var err, socket, trySockets, _i, _len, _ref;
    trySockets = this.sockets.slice(0);
    if (this.lastSocket) {
      trySockets.unshift(this.lastSocket);
    }
    for (_i = 0, _len = trySockets.length; _i < _len; _i++) {
      socket = trySockets[_i];
      try {
        if (socket.readyState === WebSocket.OPEN) {
          socket.send(data);
          if (socket.url !== ((_ref = this.lastSocket) != null ? _ref.url : void 0)) {
            this.lastSocket = socket;
            this.onserver({
              server: socket.url
            });
          }
          return;
        } else {
          socket.connect();
        }
      } catch (_error) {
        err = _error;
        this.onerror(err);
      }
    }
  };

  HuntingWebsocket.prototype.close = function() {
    var socket, _i, _len, _ref;
    _ref = this.sockets;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      socket = _ref[_i];
      socket.close();
    }
    return this.onclose();
  };

  HuntingWebsocket.prototype.onopen = function(event) {};

  HuntingWebsocket.prototype.onreconnect = function(event) {};

  HuntingWebsocket.prototype.onclose = function(event) {};

  HuntingWebsocket.prototype.onserver = function(event) {};

  HuntingWebsocket.prototype.onmessage = function(event) {};

  HuntingWebsocket.prototype.onerror = function(event) {};

  return HuntingWebsocket;

})();

module.exports = HuntingWebsocket;
