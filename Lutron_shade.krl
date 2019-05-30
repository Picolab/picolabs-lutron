ruleset Lutron_shade {
  meta {
    shares __testing, status
    provides status
  }

  global {
    __testing = { "queries": [ { "name": "__testing" },
                              { "name": "status" } ],
                  "events": [ { "domain": "lutron", "type": "shadesOpen",
                                "attrs": [ "percentage" ] },
                              { "domain": "lutron", "type": "shadesClose" } ] }

    status = function() {
      command = "?SHADEGRP," + ent:IntegrationID + ",1";
      response = telnet:query(command);
      percentage = response.extract(re#(\d+)[.]#)[0];
      status = (percentage == "0") => "closed" | percentage + "% open";
      "Shade "+ ent:IntegrationID + " is " + status
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

    if (attrs{"Rx_role"}.lc() == "shade") then noop()

    fired {
      raise wrangler event "pending_subscription_approval"
        attributes attrs;
      log info "auto accepted subscription."
    }
  }

  rule Send_Command_shadeOpen {
    select when lutron shadesOpen
    pre {
      open_percentage = event:attr("percentage") || 100
      command = "#SHADEGRP," + ent:IntegrationID + ",1," + open_percentage
      result = telnet:sendCMD(command)
    }
    send_directive("shade", {"result": result})
  }

  rule Send_Command_shadeClose {
    select when lutron shadesClose
    pre {
      command = "#SHADEGRP," + ent:IntegrationID + ",1,0"
      result = telnet:sendCMD(command)
    }
    send_directive("shade", {"result": result})
  }
}
