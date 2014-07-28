    EpiClient = require './epi-client'

EpiBufferingClient
==================
This is a subclass of the [EpiClient](epi-client.litcoffee) that simplifies querying by aggregating the results of a query and providing a query callback mechanism instead of tracking queries by hand.

    class EpiBufferingClient extends EpiClient
      constructor: (@url) ->
        super(@url)
        @results = {}
        @callbacks = {}

When a row set is began, a new object is inserted into the local **results** that will be populated with that row set as the rows come in.  Each time a new row set is began, the process starts over.

      onbeginrowset: (msg) =>
        newResultSet = []
        @results[msg.queryId] ||= resultSets: []
        @results[msg.queryId].currentResultSet = newResultSet
        @results[msg.queryId].resultSets.push newResultSet

      onrow: (msg) =>
        @results[msg.queryId].currentResultSet.push(msg.columns)

The **exec** function is analgous to the **query** function of the [EpiClient](epi-client.litcoffee) except it replaces the queryId argument with an optional callback.  It has two callback mechanisms, you may choose one.  If you provide a callback, that will be used.  Otherwise, exec will return a promise that will be called upon query completion.

Internally, it's generating a queryId for you and uses that to track the query and aggregate results.

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


    module.exports = EpiBufferingClient