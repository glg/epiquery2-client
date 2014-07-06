EpiClient = require './epi-client'

class EpiBufferingClient extends EpiClient
  constructor: (@url) ->
    super(@url)
    @results = {}

  onrow: (msg) =>
    @results[msg.queryId].currentResultSet.push(msg.columns)

  onbeginrowset: (msg) =>
    newResultSet = []
    @results[msg.queryId] ||= resultSets: []
    @results[msg.queryId].currentResultSet = newResultSet
    @results[msg.queryId].resultSets.push newResultSet

module.exports = EpiBufferingClient