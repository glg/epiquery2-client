var EpiBufferingClient, EpiClient,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

EpiClient = require('./epi-client');

EpiBufferingClient = (function(_super) {
  __extends(EpiBufferingClient, _super);

  function EpiBufferingClient(url) {
    this.url = url;
    this.onbeginrowset = __bind(this.onbeginrowset, this);
    this.onrow = __bind(this.onrow, this);
    EpiBufferingClient.__super__.constructor.call(this, this.url);
    this.results = {};
  }

  EpiBufferingClient.prototype.onrow = function(msg) {
    return this.results[msg.queryId].currentResultSet.push(msg.columns);
  };

  EpiBufferingClient.prototype.onbeginrowset = function(msg) {
    var newResultSet, _base, _name;
    newResultSet = [];
    (_base = this.results)[_name = msg.queryId] || (_base[_name] = {
      resultSets: []
    });
    this.results[msg.queryId].currentResultSet = newResultSet;
    return this.results[msg.queryId].resultSets.push(newResultSet);
  };

  return EpiBufferingClient;

})(EpiClient);

module.exports = EpiBufferingClient;
