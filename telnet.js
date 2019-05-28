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
  "initialLFCR": true,
  "timeout": 150000
}

var getHost = function() {
  return parameters.host
}

connection.on('ready', function (prompt) {
  console.log('ready!')
})

connection.on('failedlogin', function (prompt) {
  console.log('failedlogin event!')
})

connection.on('writedone', function (prompt) {
  console.log('writedone event!')
})

connection.on('connect', function (prompt) {
  console.log('telnet connection established!')
  connection.send(parameters.username + '\r\n' + parameters.password + '\r\n', null,
  function (err, response) {
    if (err) {
      console.error(err)
    }
    console.log('login cmd response', response)
  })
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
      'sendCMD': mkKRLaction([
        'command'
      ], function (ctx, args) {
        if (!_.has(args, 'command')) {
          throw new Error('telnet:sendCMD needs a command string')
        }
        console.log('send cmd args', args)
        connection.send(args.command + '\r\n', null, function (err, response) {
          if (err) {
            console.error(err)
            return err
          }
          console.log('send cmd results', response)
          return response
        })
      }),
      'connect': mkKRLaction([
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
        } catch (err) {
          console.error(err);
          return err
        }
      }),
      'getLightsFromXML':  mkKRLfn([
        'xml'
      ], function (ctx, args) {
        if (!_.has(args, 'xml')) {
          throw new Error('telnet:getLightsFromXML requires an xml string')
        }
        var doc = new DOMParser().parseFromString(args.xml)
        var lightElements = doc.getElementsByTagName("Output")
        var lights = []

        for (i = 0; i < lightElements.length; i++) {
          var lightID = lightElements[i].getAttribute("IntegrationID")
          var isShade = lightElements[i].getAttribute("OutputType") == "SYSTEM_SHADE" ? true : false
          if (!isShade) {
            lights.push(lightID)
          }
        }
        return lights
      }),
      'getShadesFromXML':  mkKRLfn([
        'xml'
      ], function (ctx, args) {
        if (!_.has(args, 'xml')) {
          throw new Error('telnet:getShadesFromXML requires an xml string')
        }
        var doc = new DOMParser().parseFromString(args.xml)
        var shadeElements = doc.getElementsByTagName("ShadeGroup")
        var shades = []

        for (i = 0; i < shadeElements.length; i++) {
          var shadeID = shadeElements[i].getAttribute("IntegrationID")
          shades.push(shadeID)
        }
        return shades
      })
    }
  }
}
