ruleset Lutron_shade {
  meta {
    use module io.picolabs.wrangler alias wrangler

    shares __testing, status, isConnected, level
    provides status, level
  }

  global {
    __testing = { "queries":
      [ { "name": "level" },
        { "name": "status" },
        { "name": "isConnected"}
      ],  "events": [
        { "domain": "lutron", "type": "shades_open", "attrs": [ "percentage" ] },
        { "domain": "lutron", "type": "shades_close" }
      ]
    }

    level = function() {
      regex = "~SHADEGRP," + ent:IntegrationID + ",1,";
      command = "?SHADEGRP," + ent:IntegrationID + ",1";
      response = telnet:query(command);
      response.extract(<<#{regex}(\d+[.]\d+)>>)[0].as("Number")
    }

    status = function() {
      percentage = level();
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

  rule auto_accept {
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

  rule shades_open {
    select when lutron shades_open
    pre {
      open_percentage = event:attr("percentage") || 100
      command = "#SHADEGRP," + ent:IntegrationID + ",1," + open_percentage
    }
    if isConnected() then
      every {
        telnet:sendCMD(command) setting(result)
        send_directive("shade", {"result": result})
      }
    notfired {
      raise lutron event "error"
        attributes { "message": "Command Not Sent: Not Logged In" }
    }
  }

  rule shades_close {
    select when lutron shades_close
    pre {
      command = "#SHADEGRP," + ent:IntegrationID + ",1,0"
    }
    if isConnected() then
      every {
        telnet:sendCMD(command) setting(result)
        send_directive("shade", {"result": result})
      }
    notfired {
      raise lutron event "error"
        attributes { "message": "Command Not Sent: Not Logged In" }
    }
  }
}
