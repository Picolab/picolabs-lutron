ruleset Lutron_manager {
  meta {
    use module io.picolabs.subscription alias subs
    use module io.picolabs.wrangler alias wrangler

    shares __testing, data, getXML, getLightIDs, getShadeIDs
    provides __testing, data
  }
  global {
    __testing = { "queries": [ { "name": "data" },
                              { "name": "getXML" },
                              { "name": "getLightIDs" },
                              { "name": "getShadeIDs" } ],
                  "events": [ { "domain": "lutron", "type": "login",
                                "attrs": [ "host", "username", "password" ] },
                              { "domain": "lutron", "type": "sendCMD",
                                "attrs": [ "cmd" ] },
                              { "domain": "lutron", "type": "create_lights" },
                              { "domain": "lutron", "type": "create_shades" },
                              { "domain": "lutron", "type": "delete_all_devices" } ] }
    getXML = function() {
      url = "http://" + telnet:host().klog("host") + "/DbXmlInfo.xml";
      http:get(url){"content"}
    }
    getLightIDs = function() {
      xml = getXML();
      telnet:getLightsFromXML(xml)
    }
    getShadeIDs = function() {
      xml = getXML();
      telnet:getShadesFromXML(xml)
    }

  }
  rule login {
    select when lutron login
    pre {
      params = {"host": event:attr("host"),
                "port": 23,
                "shellPrompt": "QNET>",
                "loginPrompt": "login:",
                "passwordPrompt": "password:",
                "username": event:attr("username"),
                "password": event:attr("password"),
                "initialLFCR": true,
                "timeout": 150000 }
    }
    telnet:connect(params)
    fired {
      raise lutron event "lightsOff"
    }
  }

  rule Send_Command {
    select when lutron sendCMD
    telnet:sendCMD(event:attr("cmd"))
  }

  rule create_light_picos {
    select when lutron create_lights
    foreach getLightIDs() setting(light)
    pre {
      name = "Light " + light
    }
    always {
      raise wrangler event "child_creation"
        attributes {
          "name": name,
          "color": "#eeee00",
          "IntegrationID": light,
          "rids": [
            "Lutron_light"
            ]
        }
    }
  }

  rule create_shade_picos {
    select when lutron create_shades
    foreach getShadeIDs() setting(shade)
    pre {
      name = "Shade " + shade
    }
    always {
      raise wrangler event "child_creation"
        attributes {
          "name": name,
          "color": "#8e8e8e",
          "IntegrationID": shade,
          "rids": [
            "Lutron_shade"
            ]
        }
    }
  }

  rule delete_all_devices {
    select when lutron delete_all_devices
    foreach wrangler:children() setting (child)
    pre {
      child_name = child{"name"}
    }
    always {
      raise wrangler event "child_deletion"
        attributes {
          "name": child_name
        }
    }
  }
}
