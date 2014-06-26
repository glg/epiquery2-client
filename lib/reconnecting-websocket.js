var ReconnectingWebSocket, WebSocket, log,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

log = require("simplog");

WebSocket = WebSocket || require('ws');

ReconnectingWebSocket = (function() {
  function ReconnectingWebSocket(url) {
    this.url = url;
    this.send = __bind(this.send, this);
    this.processMessageBuffer = __bind(this.processMessageBuffer, this);
    this.connect = __bind(this.connect, this);
    this.forceClose = false;
    this.messageBuffer = [];
    this.connect();
    this.processMessageBufferInterval;
  }

  ReconnectingWebSocket.prototype.connect = function() {
    var error, _ref, _ref1;
    try {
      if ((_ref = this.ws) != null) {
        _ref.onmessage = null;
      }
      if ((_ref1 = this.ws) != null) {
        _ref1.close();
      }
    } catch (_error) {
      error = _error;
      log.error("unexpected error cleaning up old socket " + error);
    }
    this.ws = new WebSocket(this.url);
    this.ws.onclose = (function(_this) {
      return function(event) {
        if (_this.forceClose) {
          return _this.onclose(event);
        }
      };
    })(this);
    this.ws.onmessage = (function(_this) {
      return function(event) {
        return _this.onmessage(event);
      };
    })(this);
    this.ws.onerror = (function(_this) {
      return function(event) {
        return _this.onerror(event);
      };
    })(this);
    return this.ws.onopen = (function(_this) {
      return function(event) {
        _this.onopen(event);
        return _this.processMessageBuffer();
      };
    })(this);
  };

  ReconnectingWebSocket.prototype.processMessageBuffer = function() {
    var error, message, _results;
    if (!this.processMessageBufferInterval) {
      this.processMessageBufferInterval = setInterval(this.processMessageBuffer, 128);
      return;
    }
    if (this.ws.readyState === 1) {
      _results = [];
      while (message = this.messageBuffer.shift()) {
        try {
          _results.push(this.ws.send(message));
        } catch (_error) {
          error = _error;
          log.debug("unable to send message, putting it back on the q");
          this.messageBuffer.push(message);
          this.connect();
          break;
        }
      }
      return _results;
    } else {
      return this.connect();
    }
  };

  ReconnectingWebSocket.prototype.send = function(message) {
    this.messageBuffer.push(message);
    return this.processMessageBuffer();
  };

  ReconnectingWebSocket.prototype.close = function() {
    this.forceClose = true;
    return this.ws.close();
  };

  ReconnectingWebSocket.prototype.onopen = function(event) {};

  ReconnectingWebSocket.prototype.onmessage = function(event) {};

  ReconnectingWebSocket.prototype.onclose = function(event) {};

  ReconnectingWebSocket.prototype.onerror = function(event) {};

  return ReconnectingWebSocket;

})();

module.exports = ReconnectingWebSocket;
