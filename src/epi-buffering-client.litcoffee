  EpiClient = require './epi-client'

EpiBufferingClient
==================
This is a subclass of the [EpiClient](epiquery-client.litcoffee) that will take care of aggregating the data for a particular query.  The client is still responsible with providing a unique queryId to the **query** function in order for this to work.  Otherwise, things get wacky.

The trick with this one is to provide a callback for the **onendquery** event.  The result of the query will be found in the **results** field indexed by its queryId.


    class EpiBufferingClient extends EpiClient
      constructor: (@url) ->
        super(@url)
        @results = {}

This is where the magic happens.  When a row set is began, a new object is inserted into the local **results** that will be populated with that row set as the rows come in.  Each time a new row set is began, the process starts over.

      onbeginrowset: (msg) =>
        newResultSet = []
        @results[msg.queryId] ||= resultSets: []
        @results[msg.queryId].currentResultSet = newResultSet
        @results[msg.queryId].resultSets.push newResultSet

      onrow: (msg) =>
        @results[msg.queryId].currentResultSet.push(msg.columns)



    module.exports = EpiBufferingClient