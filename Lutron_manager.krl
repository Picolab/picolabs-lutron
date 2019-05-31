ruleset Lutron_manager {
  meta {
    use module io.picolabs.wrangler alias wrangler

    shares __testing, data, extractData, getXML, getLightIDs, getShadeIDs, getAreaIDs,
            isConnected, lightIDs, shadeIDs, getChildByName
    provides data, isConnected
  }
  global {
    __testing = { "queries": [ { "name": "data" },
                              { "name": "extractData" },
                              { "name": "isConnected" },
                              { "name": "getXML" },
                              { "name": "getLightIDs" },
                              { "name": "getShadeIDs" },
                              { "name": "lightIDs" },
                              { "name": "shadeIDs" },
                              { "name": "getChildByName", "args": [ "name" ] } ],
                  "events": [ { "domain": "lutron", "type": "login",
                                  "attrs": [ "host", "username", "password" ] },
                              { "domain": "lutron", "type": "logout" },
                              { "domain": "lutron", "type": "sync_data"},
                              { "domain": "lutron", "type": "sendCMD",
                                  "attrs": [ "cmd" ] },
                              { "domain": "lutron", "type": "create_lights" },
                              { "domain": "lutron", "type": "create_shades" },
                              { "domain": "lutron", "type": "create_default_areas" },
                              { "domain": "lutron", "type": "create_group",
                                  "attrs": [ "name" ] },
                              { "domain": "lutron", "type": "add_device_to_group",
                                  "attrs": [ "deviceName", "groupName" ] },
                              { "domain": "lutron", "type": "add_group_to_group",
                                  "attrs": [ "childGroupName", "parentGroupName" ] } ] }
    data = function() {
      ent:data
    }
    extractData = function() {
      xml = getXML();
      telnet:extractDataFromXML(xml)
    }
    isConnected = function() {
      ent:isConnected.defaultsTo(false)
    }
    getXML = function() {
      url = "http://" + telnet:host().klog("host") + "/DbXmlInfo.xml";
      http:get(url){"content"}
    }
    getLightIDs = function() {
      ent:data.map(function(v,k) {
        v{"lights"}
      }).filter(function(v,k) {
        v != []
      }).values().reduce(function(a,b) {
        a.append(b)
      })
    }
    getShadeIDs = function() {
      ent:data.map(function(v,k) {
        v{"shades"}
      }).filter(function(v,k) {
        v != []
      }).values().reduce(function(a,b) {
        a.append(b)
      })
    }
    lightIDs = function() {
      ent:lightIDs
    }
    shadeIDs = function() {
      ent:shadeIDs
    }
    areaIDs = function() {
      ent:areaIDs
    }
    getChildByName = function(name) {
      wrangler:children().filter(function(x) {
        x{"name"} == name
      })[0]
    }
  }

  rule lutron_online {
    select when system online
    always {
      ent:isConnected := false
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
                "failedLoginMatch": "bad login",
                "initialLFCR": true,
                "timeout": 150000 }
      result = telnet:connect(params)
      status = (result.extract(re#(QNET>+)#)[0]).klog("extracted") => "success" | "failed"
    }
    send_directive("telnet", {"status": status, "result": result})
    fired {
      ent:isConnected := true if status == "success";
      raise lutron event "sync_data" if ent:isConnected
    }
  }

  rule logout {
    select when lutron logout
    pre {
      result = telnet:disconnect()
    }
    always {
      ent:isConnected := false
    }
  }

  rule sync_data {
    select when lutron sync_data
    pre {
      data = extractData()
    }
    always {
      ent:data := data
    }
  }

  rule send_command {
    select when lutron sendCMD
    pre {
      result = telnet:sendCMD(event:attr("cmd"))
    }
    send_directive("command",{"result": result})
  }

  rule create_light_picos {
    select when lutron create_lights
    foreach getLightIDs() setting(light)
    pre {
      name = "Light " + light
      exists = ent:lightIDs.any(function(x) { x == light })
    }
    if not exists then noop()
    fired {
      raise wrangler event "child_creation"
        attributes {
          "name": name,
          "color": "#eeee00",
          "IntegrationID": light,
          "rids": [
            "Lutron_light"
            ]
        };
      ent:lightIDs := ent:lightIDs.defaultsTo([]).append(light)
    }
  }

  rule create_shade_picos {
    select when lutron create_shades
    foreach getShadeIDs() setting(shade)
    pre {
      name = "Shade " + shade
      exists = ent:shadeIDs.any(function(x) { x == shade })
    }
    if not exists then noop()
    fired {
      raise wrangler event "child_creation"
        attributes {
          "name": name,
          "color": "#8e8e8e",
          "IntegrationID": shade,
          "rids": [
            "Lutron_shade"
            ]
        };
      ent:shadeIDs := ent:shadeIDs.defaultsTo([]).append(shade)
    }
  }

  rule create_area_picos {
    select when lutron create_default_areas
    foreach ent:data setting(area)
    pre {
      name = area{"name"}
      id = area{"id"}
      lights = area{"lights"}
    }
    if (lights != []) then noop()
    fired {
      raise wrangler event "child_creation"
        attributes {
          "name": name,
          "IntegrationID": id,
          "light_ids": lights,
          "color": "#EB4839",
          "rids": [
            "Lutron_area"
            ]
        }
    }
  }

  rule create_lutron_group {
    select when lutron create_group
    pre {
      sequence = ent:numGroups.defaultsTo(0) + 1
      name = event:attr("name") || false
    }
    if name then noop()
    fired {
      raise wrangler event "child_creation"
        attributes {
          "name": name,
          "color": "#3CAD5E",
          "rids": [
            "Lutron_group"
            ]
        };
    }
    else {
      raise lutron event "error"
        attributes {"message": "Must provide a name for the new lutron group"}
    }
  }

  rule add_device_to_group {
    select when lutron add_device_to_group
    pre {
      device_eci = getChildByName(event:attr("deviceName")){"eci"}.klog("device_eci")
      group_eci = getChildByName(event:attr("groupName")){"eci"}.klog("group_eci")
      device_type = event:attr("deviceName").substr(0,5)
    }
    if (device_eci && group_eci) then
    event:send(
      {
        "eci": group_eci, "eid": "subscription",
        "domain": "wrangler", "type": "subscription",
        "attrs": {
          "name": event:attr("deviceName"),
          "Rx_role": "controller",
          "Tx_role": device_type,
          "channel_type": "subscription",
          "wellKnown_Tx": device_eci
        }
      })

    notfired {
      raise lutron event "error"
        attributes {"message": "Invalid deviceName or groupName"}
    }
  }

  rule add_group_to_group {
    select when lutron add_group_to_group
    pre {
      child_group_eci = getChildByName(event:attr("childGroupName")){"eci"}.klog("child_eci")
      parent_group_eci = getChildByName(event:attr("parentGroupName")){"eci"}.klog("parent_eci")
    }
    if (child_group_eci && parent_group_eci) then
    event:send(
      {
        "eci": parent_group_eci, "eid": "subscription",
        "domain": "wrangler", "type": "subscription",
        "attrs": {
          "name": event:attr("childGroupName"),
          "Rx_role": "controller",
          "Tx_role": "group",
          "channel_type": "subscription",
          "wellKnown_Tx": child_group_eci
        }
      })

    notfired {
      raise lutron event "error"
        attributes {"message": "Invalid childGroupName or parentGroupName"}
    }
  }

  rule handle_error {
    select when lutron error
    send_directive("lutron_error", {"message": event:attr("message")})
  }
}
