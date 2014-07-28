    EpiBufferingClient    = require('./epi-buffering-client')
    guid                  = require './guid'
    q                     = require 'q'

EpiSimpleClient
===============
The EpiSimpleClient inherits from [EpiBufferingClient](epi-buffering-client.litcoffee) and changes the format of the rows from an array of key/value pairs into an object with named fields that contain values.

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

    module.exports = EpiSimpleClient