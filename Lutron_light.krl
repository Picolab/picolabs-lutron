ruleset Lutron_light {
  meta {
    use module io.picolabs.subscription alias subs

    shares __testing, data
    provides __testing, data
  }
  global {
    __testing = { "queries": [ { "name": "data" } ],
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
    data = function() {
      command = "?OUTPUT," + ent:IntegrationID + ",1";
      response = telnet:query(command);
      percentage = response.extract(re#(\d+)[.]#)[0];
      status = (percentage == "0") => "off" | "at " + percentage + "% brightness";
      "Light "+ ent:IntegrationID + " is " + status
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
    }
    telnet:sendCMD(command)
  }

  rule Send_Command_lightsOff {
    select when lutron lightsOff
    pre {
      command = "#OUTPUT," + ent:IntegrationID + ",1,0"
    }
    telnet:sendCMD(command)
  }

  rule Send_Command_setBrightness {
    select when lutron setBrightness
    pre {
      brightness = event:attr("brightness")
      command = "#OUTPUT," + ent:IntegrationID + ",1," + brightness
    }
    if (brightness != null && brightness != "") then
    telnet:sendCMD(command)
  }

  rule Send_Command_flash {
    select when lutron flash
    pre {
      fade_time = event:attr("fade_time") || 5
      delay = event:attr("delay") || 0
      command = "#OUTPUT," + ent:IntegrationID + ",5," + fade_time + "," + delay
    }
    telnet:sendCMD(command)
  }

  rule Send_Command_stopFlash {
    select when lutron stopFlash
    pre {
      command = "#OUTPUT," + ent:IntegrationID + ",4"
    }
    telnet:sendCMD(command)
  }
}
