EpiBufferingClient    = require('./epi-buffering-client')
guid                  = require './guid'
q                     = require 'q'

class EpiSimpleClient extends EpiBufferingClient
  constructor: (@url) ->
    super(@url)
    @callbacks = {}

  onrow: (msg) =>
    row = {}

    msg.columns.forEach (column) ->
      row[column.name] = column.value

    @results[msg.queryId].currentResultSet.push(row)

  exec: (connectionName, template, data, callback) =>
    queryId = guid()

    deferred = q.defer()
    if callback
      @callbacks[queryId] = callback
    else
      @callbacks[queryId] = deferred

    @query(connectionName, template, data, queryId)

    deferred.promise

  onendquery: (msg) =>
    return unless callback = @callbacks[msg.queryId]

    if callback.promise
      callback.resolve(@results[msg.queryId])
    else
      callback(null, @results[msg.queryId])

    delete @callbacks[msg.queryId]

  onerror: (msg) =>
    return unless callback = @callbacks[msg.queryId]

    if callback.promise
      callback.reject(@results[msg.queryId])
    else
      callback(msg)

    delete @callbacks[msg.queryId]

module.exports = EpiSimpleClient