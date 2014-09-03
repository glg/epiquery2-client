Overview
================

**TL;DR** - Go use the [EpiBufferingClient](#epibufferingclient).

### Get it
    npm install epiquery2-client

These are the clients that are available for the [epiquery2](https://github.com/igroff/epiquery2) service.

1. [EpiBufferingClient](src/epi-buffering-client.litcoffee) (recommended)
2. [EpiClient](src/epi-client.litcoffee)


Out of the box, they feature automatic reconnect, failover and socket hunting.  Due to this, all clients can be configured with either a single epiquery endpoint or multiple endpoints.

    var EpiClient = require("epiquery2-client").EpiClient;
    
    var singleServerClient = new EpiBufferingClient('ws://localhost:7171/sockjs/websocket');
    
    var multiServerClient = new EpiBufferingClient([
        'ws://localhost:7171/sockjs/websocket',
        'ws://localhost:8181/sockjs/websocket',
    ]);

### EpiBufferingClient

This is probably the simplest way to start querying.  You can either specify a call back for querying or you can use promises.  

    var EpiBufferingClient = require("epiquery2-client").EpiBufferingClient;
    
    var client = new EpiBufferingClient('ws://localhost:7171/sockjs/websocket');
    
    //Use a promise
    p = client.exec("glglive", 'councilMember/game/getAchievements.mustache', {cmId: 28})
    p.then(function(results) { console.log(results); });
    p.fail(function(err) { console.log(err); })
    
    //Use a callback
    client.exec("glglive", 'councilMember/game/getAchievements.mustache', {cmId: 28}, function(err, results){
        console.log(err, results);
    });

The **results** returned to the callback and promise is an array of row sets.  Each row set is an array of rows.  Each row is an object whose fields are named after the columns of the query.  Each field contains the value of its associated column.  

To visualize,

    [ //Row Sets
        [ //Row Set 0
            { //Row 0
                "USER_ID": "4321", //Column 0
                "FAVORITE_COLOR": "Red" //Column 1
            }, 
            { //Row 1
                "USER_ID": "6789", //Column 0
                "FAVORITE_COLOR": "Blue" //Column 1
            } 
        ],
        [ //Row Set 1
            { "COUNTRY": "USA" }, //Row 0
            { "COUNTRY": "Canada" } //Row 1
        ]
    ]
    
As a warning, uniquely name all of your columns.  Otherwise, the last identically named column to be read will "win" and you'll never see the other values.    
   
### EpiClient

The vanilla EpiClient gives you more control over the lifecycle of the query.  The main difference with the EpiBufferingClient is that you pass a queryId to the **query** function and then monitor the events of the client so that you can correlate the original query to the data you're building.  

Most of the time, you probably don't need this level of control.  Use discretion.  Here's an example of multiple, concurrent queries (this is not an issue with the EpiBufferingClient).

    var EpiClient = require("epiquery2-client").EpiClient;
    
    var client = new EpiClient('ws://localhost:7171/sockjs/websocket');
    
    var oneRows = [];
    var twoRows = [];
    var queryOne = '1';
    var queryTwo = '2';
    
    client.onrow = function(msg){
        if(msg.queryId == queryOne){
            oneRows.push(msg.columns);
        } 
        if(msg.queryId == queryTwo) {
            twoRows.push(msg.columns);
        }
    };
    
    client.onendquery = function(msg){
        if(msg.queryId == queryOne){
            console.log("All done with query one", oneRows);
        } 
        if(msg.queryId == queryTwo) {
            console.log("All done with query two", twoRows);
        }
    };
    
    client.query("glglive", 'councilMember/game/getAchievements.mustache', {cmId: 1}, queryOne);
    
    client.query("glglive", 'councilMember/game/getAchievements.mustache', {cmId: 2}, queryTwo);
    
The rows are collected in the onrow callback outlined above.  The message passed to this event contains a field called **columns** that is an array of key/value pairs.  The key is the name of the column and the value is the value of that column being returned.  Here is an example message.

    {
        "queryId": "1234",  //Optional
        "columns": [
            {
                "USER_ID": "4321"
            },
            {
                "ACTIVE_IND": 1
            },
            {
                "FAVORITE_COLOR": "Red"
            }
        ]
    }