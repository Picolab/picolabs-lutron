var _ = require('lodash')
var DOMParser = require('xmldom').DOMParser
var mkKRLfn = require('../mkKRLfn')
var mkKRLaction = require('../mkKRLaction')
var Telnet = require('telnet-client')

var connection = new Telnet()
// default parameters
var parameters = {
  "host": '127.0.0.1',
  "port": 23,
  "shellPrompt": "QNET>",
  "loginPrompt": "login:",
  "passwordPrompt": "password:",
  "username": 'root',
  "password": 'guest',
  "failedLoginMatch": "bad login",
  "initialLFCR": true,
  "timeout": 150000
}

var getHost = function() {
  return parameters.host
}

connection.on('ready', function (prompt) {
  console.log('ready!')
})

connection.on('failedlogin', function (msg) {
  console.log('failedlogin event!', msg)
})

connection.on('writedone', function (prompt) {
  console.log('writedone event!')
})

connection.on('connect', function (prompt) {
  console.log('telnet connection established!')
})

connection.on('timeout', function () {
  console.log('socket timeout!')
  // connection.end()
})

connection.on('close', function () {
  console.log('connection closed')
})

module.exports = function (core) {
  return {
    def: {
      'host': mkKRLfn([
      ], function (ctx, args) {
        return getHost()
      }),
      'connect': mkKRLfn([
        'params'
      ], function (ctx, args) {
        if (!_.has(args, 'params')) {
          throw new Error('telnet:connect requires a map of parameters')
        }
        if (!_.has(args.params, 'username')
        || !_.has(args.params, 'password')) {
          throw new Error('telnet:connect(params): params requires a username, and password')
        }
        Object.keys(args.params).forEach(function(key) {
          parameters[key] = args.params[key]
        })
        try {
          connection.connect(parameters)
          let res = connection.send(parameters.username + '\r\n' + parameters.password + '\r\n', null,
          function (err, response) {
            if (err) {
              console.error(err)
              return err
            }
            console.log('login cmd response', response)
            return response
          })
          return res
        } catch (err) {
          console.error(err);
          return err
        }
      }),
      'disconnect': mkKRLfn([
      ], function (ctx, args) {
        try {
          let res = connection.end()
          return res
        } catch (err) {
          console.error(err)
          return err
        }
      }),
      'sendCMD': mkKRLfn([
        'command'
      ], function (ctx, args) {
        if (!_.has(args, 'command')) {
          throw new Error('telnet:sendCMD needs a command string')
        }
        console.log('send cmd args', args)
        let res = connection.send(args.command + '\r\n', null, function (err, response) {
          if (err) {
            console.error(err)
            return err
          }
          console.log('send cmd results', response)
          return response
        })
        return res
      }),
      'query': mkKRLfn([
        'command'
      ], function (ctx, args) {
        if (args.command.substring(0,1) !== "?") {
          throw new Error('telnet:query(q): q must begin with a ?')
        }
        console.log('send query args', args)
        let res = connection.send(args.command + '\r\n', null, function(err, response) {
          if (err) {
            console.error(err)
            return err
          }
          console.log('send query results', response)
          return response
        })
        return res
      }),
      'extractDataFromXML': mkKRLfn([
        'xml'
      ], function(ctx, args) {
        if (!_.has(args, 'xml')) {
          throw new Error('telnet:getAreasFromXML requires an xml string')
        }
        var doc = new DOMParser().parseFromString(args.xml)
        var areaElements = doc.getElementsByTagName("Area")
        var data = {}

        for (i = 0; i < areaElements.length; i++) {
          var areaName = areaElements[i].getAttribute("Name")
          var areaID = areaElements[i].getAttribute("IntegrationID")

          var outputs = areaElements[i].getElementsByTagName("Outputs")[0]
          var lightElements = outputs.getElementsByTagName("Output")
          var lights = []
          for (j = 0; j < lightElements.length; j++) {
            var id = lightElements[j].getAttribute("IntegrationID")
            var isShade = lightElements[j].getAttribute("OutputType") == "SYSTEM_SHADE" ? true : false
            if (!isShade) {
              lights.push(id)
            }
          }

          var shadegroups = areaElements[i].getElementsByTagName("ShadeGroups")[0]
          var shadeElements = shadegroups.getElementsByTagName("ShadeGroup")
          var shades = []
          for (j = 0; j < shadeElements.length; j++) {
            var id = shadeElements[j].getAttribute("IntegrationID")
            shades.push(id)
          }

          data[areaName] = {"name": areaName, "id": areaID, "type": "area",
                            "lights": lights, "shades": shades }
        }
        return data
      })
    }
  }
}
