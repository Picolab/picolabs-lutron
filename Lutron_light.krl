ruleset Lutron_light {
  meta {
    use module io.picolabs.wrangler alias wrangler

    shares __testing, status, isConnected
    provides __testing, status
  }
  global {
    __testing = { "queries": [ { "name": "status" },
                              { "name": "isConnected" } ],
                  "events": [ { "domain": "lutron", "type": "lightsOn",
                                "attrs": [  ] },
                              { "domain": "lutron", "type": "lightsOff",
                                "attrs": [  ] },
                              { "domain": "lutron", "type": "setBrightness",
                                "attrs": [ "brightness" ] },
                              { "domain": "lutron", "type": "flash",
                                "attrs": [ "fade_time", "delay" ] },
                              { "domain": "lutron", "type": "stopFlash",
                                "attrs": [ ] } ]}
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

  rule autoAccept {
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

  rule Send_Command_lightsOn {
    select when lutron lightsOn
    pre {
      command = "#OUTPUT," + ent:IntegrationID + ",1,100"
      result = isConnected() => telnet:sendCMD(command)
            | "Command Not Sent: Not Logged In"
    }
    send_directive("light", {"result": result})
  }

  rule Send_Command_lightsOff {
    select when lutron lightsOff
    pre {
      command = "#OUTPUT," + ent:IntegrationID + ",1,0"
      result = isConnected() => telnet:sendCMD(command)
            | "Command Not Sent: Not Logged In"
    }
    send_directive("light", {"result": result})
  }

  rule Send_Command_setBrightness {
    select when lutron setBrightness
    pre {
      brightness = event:attr("brightness").defaultsTo(brightness())
      command = "#OUTPUT," + ent:IntegrationID + ",1," + brightness
      result = isConnected() => telnet:sendCMD(command)
            | "Command Not Sent: Not Logged In"
    }
    send_directive("light", {"result": result})
  }

  rule Send_Command_flash {
    select when lutron flash
    pre {
      fade_time = event:attr("fade_time") || 5
      delay = event:attr("delay") || 0
      command = "#OUTPUT," + ent:IntegrationID + ",5," + fade_time + "," + delay
      result =isConnected() => telnet:sendCMD(command)
            | "Command Not Sent: Not Logged In"
    }
    send_directive("light", {"result": result})
  }

  rule Send_Command_stopFlash {
    select when lutron stopFlash
    pre {
      command = "#OUTPUT," + ent:IntegrationID + ",4"
      result = isConnected() => telnet:sendCMD(command)
            | "Command Not Sent: Not Logged In"
    }
    send_directive("light", {"result": result})
  }
}
