EpiBufferingClient
==================

    EpiClient = require './epi-client'
    guid      = require './guid'
    q         = require 'q'

This simplifies querying by aggregating the results of a query and providing a query callback mechanism instead of tracking queries by hand.

    class EpiBufferingClient

      constructor: (url) ->

        @results = {}
        @callbacks = {}

When a row set is began, a new object is inserted into the local **results** that will be populated with that row set as the rows come in.  Each time a new row set is began, the process starts over.

        @client = new EpiClient(url)
        @client.onbeginrowset = (msg) =>
          newResultSet = []
          @results[msg.queryId] ||= resultSets: []
          @results[msg.queryId].currentResultSet = newResultSet
          @results[msg.queryId].resultSets.push newResultSet

Each time a row is returned, it turns the key/value pair into properties on an object.  The downside is that if you
have multiple columns with the same name, this will eat them.  But then how would you have figured out which was which
anyways?  Just give your columns unique names and avoid the issue.

        @client.onrow = (msg) =>
          row = {}

          msg.columns.forEach (column) ->
            row[column.name] = column.value

          @results[msg.queryId].currentResultSet.push(row)

When the query completes, we call back to either the promise or user-provided callback.

        @client.onendquery = (msg) =>
          return unless callback = @callbacks[msg.queryId]

          if callback.promise
            callback.resolve(@results[msg.queryId])
          else
            callback(null, @results[msg.queryId])

          delete @callbacks[msg.queryId]

If the query drops out due to error, we call back to either the promise or user-provided callback.

        @client.onerror = (msg) =>
          return unless callback = @callbacks[msg.queryId]

          if callback.promise
            callback.reject(msg)
          else
            callback(msg)

          delete @callbacks[msg.queryId]

The **query** function is analogous to the **query** function of the [EpiClient](epi-client.litcoffee) except it replaces the queryId argument with an optional callback.  It has two callback mechanisms, you may choose one.  If you provide a callback, that will be used.  Otherwise, exec will return a promise that will be called upon query completion.

Internally, it's generating a queryId for you and uses that to track the query and aggregate results.

      query: (connectionName, template, data, callback) =>
        queryId = guid()

        deferred = q.defer()
        if callback
          @callbacks[queryId] = callback
        else
          @callbacks[queryId] = deferred

        @client.query(connectionName, template, data, queryId)

        deferred.promise

    module.exports = EpiBufferingClient