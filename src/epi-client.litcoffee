EpiClient
=========

    EventEmitter      = require('events').EventEmitter
    _                 = require 'underscore'
    log               = require 'simplog'
    AwesomeWebSocket  = require('awesome-websocket').AwesomeWebSocket

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
        @ws.onerror = (err) =>
          @emit 'error', err

The **query** function kicks off the processing of a query which triggers a handful of events in the lifecycle of a query.  See the events section below for more details.

**connectionName** - The string key that maps to an epiquery2 named connection e.g. 'mysql', 'mssql', 'file'.  See more [here](https://github.com/igroff/epiquery2#configuration).

**template** - The path to the template you're querying.  The path is relative to the root of the template directory defined in epiquery2.

**data** - This is a just javascript object you can pass that contains any data you want to use in your epiquery template.

**queryId** - A unique identifier used to refer to the query throughout it's Active period. It will be included with all messages generated during it's processing. It is the caller's responsibility to generate a unique id for each query requested.

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
        @ws.send req

Echoes events returned from epiquery.

      onMessage: (event) =>
        # if the browser has wrapped this for use, we'll be interested in its
        # 'data' element
        message = event.data
        message = JSON.parse(message) if typeof message is 'string'
        handler = @['on' + message.message]
        if handler
          handler(message)

      onClose: () =>
        @emit 'close'

## Events
They're all pretty self explanatory.  The messages provided to the events have the optional field **queryId** that corresponds to the  queryId that was provided to the **query** function.  Use that to track the lifecycle of a particular query.

Invoked at the start of the query's lifecycle.  Important to note, this is the beginning of the whole epiquery request, not individual statements in the request.

      onbeginquery: (msg) => @emit 'beginquery', msg

Invoked when a new row set is began.  Row sets are the result of executing an individual statement.  For example, if you executed two SQL statements, each would be its own row set.

      onbeginrowset: (msg) => @emit 'beginrowset', msg

Invoked every time a row of data is returned from a row set.

      onrow: (msg) => @emit 'row', msg

Invoked at the end of a row set.

      onendrowset: (msg) => @emit 'endrowset', msg

Invoked at the end of the query's overall lifecycle.

      onendquery: (msg) => @emit 'endquery', msg

Invoked if an error is encountered while processing the query.

      onerror: (msg) => @emit 'error', msg



    module.exports = EpiClient