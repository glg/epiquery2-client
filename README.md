Overview
================



This is the group of clients that are available for the [epiquery2](https://github.com/igroff/epiquery2) service.  There are three choices:

1. [EpiBufferingClient](src/epi-buffering-client.litcoffee) (recommended)
2. [EpiClient](src/epi-client.litcoffee)
3. [EpiSimpleClient](src/epi-simple-client.litcoffee)

In addition to a simplified interface, they also feature automatic reconnect, failover and socket hunting.  Due to this, all clients can be configured with either a single epiquery endpoint or multiple endpoints.  For example, you can provide a single string to the constructor or an array of strings each representing an endpoint.

    var EpiClient = require("epiquery2-client").EpiClient;
    
    var oneServerClient = new EpiBufferingClient('ws://localhost:7171/sockjs/websocket');
    
    var multiServerClient = new EpiBufferingClient([
        'ws://localhost:7171/sockjs/websocket',
        'ws://localhost:8181/sockjs/websocket',
    ]);

## TL;DR 
Go use the [EpiBufferingClient](#epibufferingclient).
    
### onrow Row data

Rows are returned to the client when the **onrow** event is triggered.  The message passed to this event contains a field called **columns** that is an array of key/value pairs.  They key is the name of the column and the value is the actual value of that column being returned.  Here is an example message.

    {
        "queryId": "1234",
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

The **results** returned to the callback and promise is an array of row sets.  Each row set is an array of rows.  Each row is an array of key/value pair columns.  To visualize,

    [
        [ //Row Set 0
            [ //Row 0
                { "USER_ID": "4321" }, //Column 0
                { "FAVORITE_COLOR": "Red" } //Column 1
            ], 
            [ //Row 1
                { "USER_ID": "6789" }, //Column 0
                { "FAVORITE_COLOR": "Blue" } //Column 1
            ] 
        ],
        [ //Row Set 1
            [ { "COUNTRY": "USA" } ], //Row 0
            [ { "COUNTRY": "Canada" } ] //Row 1
        ]
    ]
    
### EpiClient

The vanilla EpiClient is a little more hands-on.  The main difference with the EpiBufferingClient is that you pass a queryId to the **query** function and then monitor the events of the client so that you can correlate the original query to the data you're building.  

Most of the time, you probably don't need this level of control.  Use your discretion.  Here's an example of multiple concurrent queries.

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

### EpiSimpleClient
This class inherits from the EpiBufferingClient and changes the way rows are represented.  Instead of a row being an array of key/value pairs, it turns the row into an object with fields and values.  The only drawback to this approach is that if there is more than one column returned with the same name, the last one read will win.  But if you've got multiple columns with the same name coming back, you've got other problems.

    var EpiSimpleClient = require("epiquery2-client").EpiSimpleClient;
    
    var client = new EpiBufferingClient('ws://localhost:7171/sockjs/websocket');
    
    //SELECT USER_ID, FAVE_COLOR FROM USERS WHERE USER_ID = ?
    p = client.exec("glglive", 'user/profile.mustache', {USER_ID: 14})
    p.then(function(results) {
        var user = results[0][0] //First row set, first row
        console.log("Favorite color is " + user.FAVE_COLOR); 
    });
    