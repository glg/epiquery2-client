  EventEmitter      = require('events').EventEmitter
    _                 = require 'underscore'
    log               = require 'simplog'
    AwesomeWebSocket  = require('awesome-websocket').AwesomeWebSocket

EpiClient
=========
This is the base client for communicating with epiquery2.

    class EpiClient extends EventEmitter

The @url constructor argument can be either a singular string or an array of strings that represent the
epiquery2 endpoint(s).

      constructor: (@url) ->
        @connect()

Under the hood, we're using the [AwesomeWebSocket](https://github.com/glg/awesome-websocket) to ensure auto-reconnect
on interruptions and endpoint hunting to find the fastest connection.

      connect: =>
        @ws = new AwesomeWebSocket(@url)
        @queryId = 0
        @ws.onmessage = @onMessage
        @ws.onclose = @onClose
        @ws.onopen = () ->
          log.debug "Epiclient connection opened"
        @ws.onerror = (err) ->
          log.error "EpiClient socket error: ", err
        @ws.onsend = @onsend

## Querying

The query function kicks off the processing of a query.

- **connectionName** - The string key that maps to an epiquery2 named connection e.g. 'mysql', 'mssql', 'file'.  See more [here](https://github.com/igroff/epiquery2#configuration).
- **template** - The path to the template you're querying.  The path is relative to the root of the template directory defined in epiquery2.
- **data** - This is a just javascript object you can pass that contains any data you want to use in your epiquery template.
- **queryId** - A unique identifier used to refer to the query throughout it's Active period. It will be included with all messages generated during it's processing. It is the caller's responsibility to generate a unique id for each query requested.

      query: (connectionName, template, data, queryId=null) =>
        req =
          templateName: template
          connectionName: connectionName
          data: data
        req.queryId = null || queryId
        req.closeOnEnd = data.closeOnEnd if data
        # if someone has asked us to close on end, we want our fancy
        # underlying reconnectint sockets to not reconnect
        @ws.forceClose = req.closeOnEnd

        log.debug "executing query: #{template} data:#{JSON.stringify(data)}"
        @ws.send JSON.stringify(req)


Echoes events returned from epiquery.

      onMessage: (message) =>
        # if the browser has wrapped this for use, we'll be interested in its
        # 'data' element
        message = message.data if message.type? and message.type = 'message'
        message = JSON.parse(message) if typeof message is 'string'
        handler = @['on' + message.message]
        if handler
          handler(message)

      onClose: () =>
        @emit 'close'

 ## Events

      onrow: (msg) => @emit 'row', msg
      onbeginquery: (msg) => @emit 'beginquery', msg
      onendquery: (msg) => @emit 'endquery', msg
      onerror: (msg) => @emit 'error', msg
      onbeginrowset: (msg) => @emit 'beginrowset', msg
      onendrowset: (msg) => @emit 'endrowset', msg
      onsend: (msg) => @emit 'send', msg


    module.exports = EpiClient