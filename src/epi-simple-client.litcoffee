    EpiBufferingClient    = require('./epi-buffering-client')
    guid                  = require './guid'
    q                     = require 'q'

EpiSimpleClient
===============
The EpiSimpleClient takes some of the legwork out of querying by providing a callback mechanism instead of having to track a query by hand.  It also changes the format of the rows returned in results from an array of key/value pairs to an object with properties.

    class EpiSimpleClient extends EpiBufferingClient
      constructor: (@url) ->
        super(@url)
        @callbacks = {}

Each time a row is returned, it turns the key/value pair into properties on an object.

      onrow: (msg) =>
        row = {}

        msg.columns.forEach (column) ->
          row[column.name] = column.value

        @results[msg.queryId].currentResultSet.push(row)

This is what makes this class convenient.  The **exec** function is analgous to the **query** function of the [EpiClient](epi-client.litcoffee) except it replaces the queryId argument with an optional callback.  It has two callback mechanisms, you may choose one.  If you provide a callback, that will be used.  Otherwise, exec will return a promise that will be called upon query completion.

Internally, it's generating a queryId for you and uses that to track the query.

      exec: (connectionName, template, data, callback) =>
        queryId = guid()

        deferred = q.defer()
        if callback
          @callbacks[queryId] = callback
        else
          @callbacks[queryId] = deferred

        @query(connectionName, template, data, queryId)

        deferred.promise

When the query completes, we call back to either the promise or user-provided callback.

      onendquery: (msg) =>
        return unless callback = @callbacks[msg.queryId]

        if callback.promise
          callback.resolve(@results[msg.queryId])
        else
          callback(null, @results[msg.queryId])

        delete @callbacks[msg.queryId]

If the query drops out due to error, we call back to either the promise or user-provided callback.

      onerror: (msg) =>
        return unless callback = @callbacks[msg.queryId]

        if callback.promise
          callback.reject(@results[msg.queryId])
        else
          callback(msg)

        delete @callbacks[msg.queryId]

    module.exports = EpiSimpleClient