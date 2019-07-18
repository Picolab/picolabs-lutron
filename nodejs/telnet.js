var _ = require('lodash')
var DOMParser = require('xmldom').DOMParser
var mkKRLfn = require('../mkKRLfn')
var mkKRLaction = require('../mkKRLaction')
var Telnet = require('telnet-client')
var ping = require('ping')

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
  "timeout": 1800000 // 30 minutes
}

var raiseEvent;

var timeoutEvent = {
  eci: "",
  eid: "telnet_socket_timeout",
  domain: "telnet",
  type: "socket_timeout",
  attrs: {
    "duration": parameters.timeout
  }
}

var getHost = function() {
  return parameters.host
}

var isValidHost = async function() {
  let response = await ping.promise.probe(parameters.host);
  console.log("isValidHost", response);
  return response.alive;
}

connection.on('ready', function (prompt) {
  console.log('ready!')
})

connection.on('writedone', function (prompt) {
  console.log('writedone event!')
})

connection.on('connect', function (prompt) {
  console.log('telnet connection established!')
})

connection.on('failedlogin', function (msg) {
  console.log('failedlogin event!', msg)
})

connection.on('timeout', function () {
  console.log('socket timeout!')
  raiseEvent(timeoutEvent)
  // connection.end()
})

connection.on('error', function () {
  console.log('telnet error!');
})

connection.on('end', function () {
  console.log('telnet host ending connection!');
})

connection.on('close', function () {
  console.log('connection closed')
})

module.exports = function (core) {
  return {
    def: {
      'parameters': mkKRLfn([
      ], function (ctx, args) {
        return parameters;
      }),
      'host': mkKRLfn([
      ], function (ctx, args) {
        return getHost()
      }),
      'connect': mkKRLaction([
        'params'
      ], async function (ctx, args) {
        if (_.has(args, 'params')) {
          Object.keys(args.params).forEach(function(key) {
            parameters[key] = args.params[key]
          })
        }

        let alive = await isValidHost();
        console.log("alive", alive);

        if (alive) {
          timeoutEvent.eci = _.get(ctx, ['event', 'eci'], _.get(ctx, ['query', 'eci']))
          timeoutEvent.timeout = parameters.timeout;
          raiseEvent = core.signalEvent;
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
        }
        return "Unable to connect to host " + parameters.host;
      }),
      'disconnect': mkKRLaction([
      ], function (ctx, args) {
        try {
          let res = connection.end()
          return res
        } catch (err) {
          console.error(err)
          return err
        }
      }),
      'sendCMD': mkKRLaction([
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
