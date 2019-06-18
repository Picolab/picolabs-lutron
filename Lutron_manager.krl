ruleset Lutron_manager {
  meta {
    use module io.picolabs.wrangler alias wrangler

    shares __testing, data, extractData, fetchXML, fetchLightIDs, fetchShadeIDs,
            fetchAreas, isConnected, lightIDs, shadeIDs, areas, getChildByName
    provides data, isConnected, lightIDs, shadeIDs, areas
  }
  global {
    __testing = { "queries":
      [ { "name": "data" },
        { "name": "extractData" },
        { "name": "isConnected" },
        { "name": "fetchXML" },
        { "name": "fetchLightIDs" },
        { "name": "fetchShadeIDs" },
        { "name": "fetchAreas" },
        { "name": "lightIDs" },
        { "name": "shadeIDs" },
        { "name": "areas" },
        { "name": "getChildByName", "args": [ "name" ] }
      ],  "events": [ { "domain": "lutron", "type": "login",
                    "attrs": [ "host", "username", "password" ] },
        { "domain": "lutron", "type": "logout" },
        { "domain": "lutron", "type": "sync_data"},
        { "domain": "lutron", "type": "sendCMD", "attrs": [ "cmd" ] },
        { "domain": "lutron", "type": "create_lights" },
        { "domain": "lutron", "type": "create_shades" },
        { "domain": "lutron", "type": "create_default_areas" },
        { "domain": "lutron", "type": "create_group", "attrs": [ "name" ] },
        { "domain": "lutron", "type": "add_device_to_group",
                    "attrs": [ "device_name", "group_name" ] },
        { "domain": "lutron", "type": "add_group_to_group",
                    "attrs": [ "child_group_name", "parent_group_name" ] }
      ]
    }

    data = function() {
      ent:data
    }
    extractData = function() {
      xml = fetchXML();
      telnet:extractDataFromXML(xml)
    }
    isConnected = function() {
      ent:isConnected.defaultsTo(false)
    }
    fetchXML = function() {
      url = "http://" + telnet:host().klog("host") + "/DbXmlInfo.xml";
      http:get(url){"content"}
    }
    fetchLightIDs = function() {
      ent:data.map(function(v,k) {
        v{"lights"}
      }).filter(function(v,k) {
        v != []
      }).values().reduce(function(a,b) {
        a.append(b)
      })
    }
    fetchShadeIDs = function() {
      ent:data.map(function(v,k) {
        v{"shades"}
      }).filter(function(v,k) {
        v != []
      }).values().reduce(function(a,b) {
        a.append(b)
      })
    }
    fetchAreas = function() {
      ent:data.keys()
    }
    lightIDs = function() {
      ent:lightIDs
    }
    shadeIDs = function() {
      ent:shadeIDs
    }
    areas = function() {
      ent:areas
    }
    getChildByName = function(name) {
      wrangler:children().filter(function(x) {
        x{"name"} == name
      })[0]
    }
    app = {"name":"Lutron Manager","version":"0.0"/* img: , pre: , ..*/};
    // image url: https://serenaprouat.lutron.com/media/wysiwyg/img_logo_lutron.gif

    bindings = function() {
      {
        // "lights": lightIDs(),
        // "shades": shadeIDs(),
        // "isConnected": isConnected()
      }
    }
  }

  rule discovery {
    select when manifold apps
    send_directive("lutron app discovered...",
      { "app": app,
        "iconURL": "https://lh3.ggpht.com/CIySCkIa6cshHVwZzEkpEyBtIfWWLLJ_w8GBKuUQRk8iXkB6sg9FbE5ZTNuuMJKRrw=s360-rw",
        "rid": meta:rid,
        "bindings": bindings()
      });
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
      isConnected = (status == "success") => true | false
    }
    send_directive("telnet", {"status": status, "isConnected": isConnected, "result": result})
    fired {
      ent:isConnected := true if isConnected;
      raise lutron event "sync_data" if isConnected
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
      update_lights = ((ent:lightIDs <=> fetchLightIDs) == 1).klog("update_lights:")
      update_shades = ((ent:lightIDs <=> fetchShadeIDs) == 1).klog("update_shades:")
      update_areas =  ((ent:lightIDs cmp fetchAreas) == 1).klog("update_areas")
    }
    always {
      ent:data := data;
      raise lutron event "create_lights" if update_lights;
      raise lutron event "create_shades" if update_shades;
      raise lutron event "create_default_areas" if update_areas
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
    foreach fetchLightIDs() setting(light)
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
    foreach fetchShadeIDs() setting(shade)
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
      exists = ent:areas.any(function(x) { x == name })
    }
    if (lights != []) && (not exists) then noop()
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
        };
      ent:areas := ent:areas.defaultsTo([]).append(name)
    }
  }

  rule create_lutron_group {
    select when lutron create_group
    pre {
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
      ent:groups := ent:groups.defaultsTo([]).append(name)
    }
    else {
      raise lutron event "error"
        attributes {"message": "Must provide a name for the new lutron group"}
    }
  }

  rule add_device_to_group {
    select when lutron add_device_to_group
    pre {
      device_eci = getChildByName(event:attr("device_name")){"eci"}.klog("device_eci")
      group_eci = getChildByName(event:attr("group_name")){"eci"}.klog("group_eci")
      device_type = event:attr("device_name").substr(0,5)
    }
    if (device_eci && group_eci) then
    event:send(
      {
        "eci": group_eci, "eid": "subscription",
        "domain": "wrangler", "type": "subscription",
        "attrs": {
          "name": event:attr("device_name"),
          "Rx_role": "controller",
          "Tx_role": device_type,
          "channel_type": "subscription",
          "wellKnown_Tx": device_eci
        }
      })

    notfired {
      raise lutron event "error"
        attributes {"message": "Invalid device_name or group_name"}
    }
  }

  rule add_group_to_group {
    select when lutron add_group_to_group
    pre {
      child_group_eci = getChildByName(event:attr("child_group_name")){"eci"}.klog("child_eci")
      parent_group_eci = getChildByName(event:attr("parent_group_name")){"eci"}.klog("parent_eci")
    }
    if (child_group_eci && parent_group_eci) then
    event:send(
      {
        "eci": parent_group_eci, "eid": "subscription",
        "domain": "wrangler", "type": "subscription",
        "attrs": {
          "name": event:attr("child_group_name"),
          "Rx_role": "controller",
          "Tx_role": "group",
          "channel_type": "subscription",
          "wellKnown_Tx": child_group_eci
        }
      })

    notfired {
      raise lutron event "error"
        attributes {"message": "Invalid child_group_name or parent_group_name"}
    }
  }

  rule handle_error {
    select when lutron error
    send_directive("lutron_error", {"message": event:attr("message")})
  }
}
