ruleset Lutron_light {
  meta {
    use module io.picolabs.wrangler alias wrangler

    shares __testing, status, isConnected, brightness
    provides __testing, status, brightness
  }
  global {
    __testing = { "queries":
      [ { "name": "brightness" },
        { "name": "status" },
        { "name": "isConnected" }
      ],  "events":
      [ { "domain": "lutron", "type": "lights_on", "attrs": [  ] },
        { "domain": "lutron", "type": "lights_off", "attrs": [  ] },
        { "domain": "lutron", "type": "set_brightness", "attrs": [ "brightness" ] },
        { "domain": "lutron", "type": "flash", "attrs": [ "fade_time", "delay" ] },
        { "domain": "lutron", "type": "stop_flash", "attrs": [ ] }
      ]
    }

    brightness = function() {
      regex = "~OUTPUT," + ent:IntegrationID + ",1,";
      command = "?OUTPUT," + ent:IntegrationID + ",1";
      response = telnet:query(command);
      response.extract(<<#{regex}(\d+[.]\d+)>>)[0].as("Number")
    }

    status = function() {
      percentage = brightness();
      status = (percentage == "0") => "off" | "at " + percentage + "% brightness";
      "Light "+ ent:IntegrationID + " is " + status
    }

    isConnected = function() {
      wrangler:skyQuery(wrangler:parent_eci(), "Lutron_manager", "isConnected", null)
    }
  }

  rule initialize {
    select when wrangler ruleset_added where event:attr("rids") >< meta:rid
    pre {
      attrs = event:attrs.klog("attrs")
      IntegrationID = event:attr("IntegrationID")
    }
    always {
      ent:IntegrationID := IntegrationID
    }
  }

  rule auto_accept {
    select when wrangler inbound_pending_subscription_added
    pre {
      attrs = event:attrs.klog("subscription: ");
    }
    //if (attrs{"Rx_role"}.lc() == "light") then
    noop()
    fired {
      raise wrangler event "pending_subscription_approval"
        attributes attrs;
      log info "auto accepted subscription."
    }
  }

  rule visual_updated {
    select when visual updated
    pre {
      dname = event:attr("dname")
      id = wrangler:myself(){"id"}
      name_changed = event:attr("was_dname") != dname
    }
    if name_changed then
    event:send(
      {
        "eci": wrangler:parent_eci(), "eid": "child_name_changed",
        "domain": "lutron", "type": "child_name_changed",
        "attrs": {"child_id": id, "child_type": "light", "new_name": dname}
      })
  }

  rule lights_on {
    select when lutron lights_on
    pre {
      command = "#OUTPUT," + ent:IntegrationID + ",1,100"
    }
    if isConnected() then
      every {
        telnet:sendCMD(command) setting(result)
        send_directive("light", {"result": result})
      }
    notfired {
      raise lutron event "error"
        attributes { "message": "Command Not Sent: Not Logged In" }
    }
  }

  rule lights_off {
    select when lutron lights_off
    pre {
      command = "#OUTPUT," + ent:IntegrationID + ",1,0"
    }
    if isConnected() then
      every {
        telnet:sendCMD(command) setting(result)
        send_directive("light", {"result": result})
      }
    notfired {
      raise lutron event "error"
        attributes { "message": "Command Not Sent: Not Logged In" }
    }
  }

  rule set_brightness {
    select when lutron set_brightness
    pre {
      brightness = event:attr("brightness").defaultsTo(brightness())
      command = "#OUTPUT," + ent:IntegrationID + ",1," + brightness
    }
    if isConnected() then
      every {
        telnet:sendCMD(command) setting(result)
        send_directive("light", {"result": result})
      }
    notfired {
      raise lutron event "error"
        attributes { "message": "Command Not Sent: Not Logged In" }
    }
  }

  rule flash {
    select when lutron flash
    pre {
      fade_time = event:attr("fade_time") || 5
      delay = event:attr("delay") || 0
    }
    if isConnected() then
      every {
        telnet:sendCMD(command) setting(result)
        send_directive("light", {"result": result})
      }
    notfired {
      raise lutron event "error"
        attributes { "message": "Command Not Sent: Not Logged In" }
    }
  }

  rule stop_flash {
    select when lutron stop_flash
    pre {
      command = "#OUTPUT," + ent:IntegrationID + ",4"
    }
    if isConnected() then
      every {
        telnet:sendCMD(command) setting(result)
        send_directive("light", {"result": result})
      }
    notfired {
      raise lutron event "error"
        attributes { "message": "Command Not Sent: Not Logged In" }
    }
  }
}
