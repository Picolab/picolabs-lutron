ruleset Lutron_light {
  meta {
    use module io.picolabs.wrangler alias wrangler

    shares __testing, status, isConnected
    provides __testing, status
  }
  global {
    __testing = { "queries":
      [ { "name": "status" },
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
      command = "?OUTPUT," + ent:IntegrationID + ",1";
      response = telnet:query(command);
      response.extract(re#(\d+)[.]#)[0];
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
      attrs = event:attr("rs_attrs")
      IntegrationID = attrs{"IntegrationID"}
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

    if (attrs{"Rx_role"}.lc() == "light") then noop()

    fired {
      raise wrangler event "pending_subscription_approval"
        attributes attrs;
      log info "auto accepted subscription."
    }
  }

  rule lights_on {
    select when lutron lights_on
    pre {
      command = "#OUTPUT," + ent:IntegrationID + ",1,100"
      result = isConnected() => telnet:sendCMD(command)
            | "Command Not Sent: Not Logged In"
    }
    send_directive("light", {"result": result})
  }

  rule lights_off {
    select when lutron lights_off
    pre {
      command = "#OUTPUT," + ent:IntegrationID + ",1,0"
      result = isConnected() => telnet:sendCMD(command)
            | "Command Not Sent: Not Logged In"
    }
    send_directive("light", {"result": result})
  }

  rule set_brightness {
    select when lutron set_brightness
    pre {
      brightness = event:attr("brightness").defaultsTo(brightness())
      command = "#OUTPUT," + ent:IntegrationID + ",1," + brightness
      result = isConnected() => telnet:sendCMD(command)
            | "Command Not Sent: Not Logged In"
    }
    send_directive("light", {"result": result})
  }

  rule flash {
    select when lutron flash
    pre {
      fade_time = event:attr("fade_time") || 5
      delay = event:attr("delay") || 0
      command = "#OUTPUT," + ent:IntegrationID + ",5," + fade_time + "," + delay
      result = isConnected() => telnet:sendCMD(command)
            | "Command Not Sent: Not Logged In"
    }
    send_directive("light", {"result": result})
  }

  rule stop_flash {
    select when lutron stop_flash
    pre {
      command = "#OUTPUT," + ent:IntegrationID + ",4"
      result = isConnected() => telnet:sendCMD(command)
            | "Command Not Sent: Not Logged In"
    }
    send_directive("light", {"result": result})
  }
}
