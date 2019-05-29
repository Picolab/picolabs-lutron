ruleset Lutron_manager {
  meta {
    use module io.picolabs.subscription alias subs
    use module io.picolabs.wrangler alias wrangler

    shares __testing, data, getXML, getLightIDs, getShadeIDs, isConnected, lightIDs, shadeIDs
    provides __testing, data
  }
  global {
    __testing = { "queries": [ { "name": "data" },
                              { "name": "isConnected" },
                              { "name": "getXML" },
                              { "name": "getLightIDs" },
                              { "name": "getShadeIDs" },
                              { "name": "lightIDs" },
                              { "name": "shadeIDs" },
                              { "name": "getChildByName", "args": [ "name" ] } ],
                  "events": [ { "domain": "lutron", "type": "login",
                                  "attrs": [ "host", "username", "password" ] },
                              { "domain": "lutron", "type": "sendCMD",
                                  "attrs": [ "cmd" ] },
                              { "domain": "lutron", "type": "create_lights" },
                              { "domain": "lutron", "type": "create_shades" },
                              { "domain": "lutron", "type": "create_group",
                                  "attrs": [ "name" ] },
                              { "domain": "lutron", "type": "add_device_to_group",
                                  "attrs": [ "deviceName", "groupName" ] },
                              { "domain": "lutron", "type": "add_group_to_group",
                                  "attrs": [ "childGroupName", "parentGroupName" ] },
                              { "domain": "lutron", "type": "delete_all_devices" } ] }
    data = function() {
      "telnet-host:" + telnet:host()
    }
    isConnected = function() {
      "not implemented yet"
    }
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
    lightIDs = function() {
      ent:lightIDs
    }
    shadeIDs = function() {
      ent:shadeIDs
    }
    getChildByName = function(name) {
      wrangler:children().filter(function(x) {
        x{"name"} == name
      })[0]
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

  rule create_lutron_group {
    select when lutron create_group
    pre {
      sequence = ent:numGroups.defaultsTo(0) + 1
      name = event:attr("name") || "Group " + sequence
    }
    always {
      raise wrangler event "child_creation"
        attributes {
          "name": name,
          "color": "#87cefa",
          "rids": [
            "Lutron_group"
            ]
        };

      ent:numGroups := sequence
    }
  }

  rule decrement_group_count {
    select when lutron decrement_group_count
    pre {
      count = ent:numGroups.defaultsTo(1) - 1
    }
    always {
      ent:numGroups := count
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
  }
}
