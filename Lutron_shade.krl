ruleset Lutron_shade {
  meta {
    use module io.picolabs.wrangler alias wrangler

    shares __testing, status, isConnected
    provides status
  }

  global {
    __testing = { "queries":
      [ { "name": "__testing" },
        { "name": "status" },
        { "name": "isConnected"}
      ],  "events": [
        { "domain": "lutron", "type": "shades_open", "attrs": [ "percentage" ] },
        { "domain": "lutron", "type": "shades_close" }
      ]
    }

    status = function() {
      command = "?SHADEGRP," + ent:IntegrationID + ",1";
      response = telnet:query(command);
      percentage = response.extract(re#(\d+)[.]#)[0];
      status = (percentage == "0") => "closed" | percentage + "% open";
      "Shade "+ ent:IntegrationID + " is " + status
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

    if (attrs{"Rx_role"}.lc() == "shade") then noop()

    fired {
      raise wrangler event "pending_subscription_approval"
        attributes attrs;
      log info "auto accepted subscription."
    }
  }

  rule Send_Command_shadeOpen {
    select when lutron shades_open
    pre {
      open_percentage = event:attr("percentage") || 100
      command = "#SHADEGRP," + ent:IntegrationID + ",1," + open_percentage
      result = isConnected() => telnet:sendCMD(command)
            | "Command Not Sent: Not Logged In"
    }
    send_directive("shade", {"result": result})
  }

  rule Send_Command_shadeClose {
    select when lutron shades_close
    pre {
      command = "#SHADEGRP," + ent:IntegrationID + ",1,0"
      result = isConnected() => telnet:sendCMD(command)
            | "Command Not Sent: Not Logged In"
    }
    send_directive("shade", {"result": result})
  }
}
