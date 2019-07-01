ruleset Lutron_group {
  meta {
    use module io.picolabs.subscription alias subscription
    use module io.picolabs.wrangler alias wrangler
    shares __testing, isConnected, devicesAndDetails
    provides devicesAndDetails
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" },
        { "name": "isConnected" },
        { "name": "devicesAndDetails" }
      ] , "events":
      [ { "domain": "lutron", "type": "group_lights_on" },
        { "domain": "lutron", "type": "group_lights_off" },
        { "domain": "lutron", "type": "group_lights_brightness", "attrs": [ "brightness" ] },
        { "domain": "lutron", "type": "group_lights_flash", "attrs": [ "fade_time", "delay" ] },
        { "domain": "lutron", "type": "group_lights_stop_flash" },
        { "domain": "lutron", "type": "group_shades_open", "attrs": [ "percentage" ] },
        { "domain": "lutron", "type": "group_shades_close" }
      ]
    }

    isConnected = function() {
      wrangler:skyQuery(wrangler:parent_eci(), "Lutron_manager", "isConnected", null)
    }

    devicesAndDetails = function() {
      subscription:established().map(function(x) {
        name = wrangler:skyQuery(x{"Tx"}, "io.picolabs.visual_params", "dname");
        {}.put(name, {"name": name, "type": x{"Tx_role"}.lc(), "eci": x{"Tx"}})
      }).reduce(function(a,b) {
        a.put(b)
      })
    }
  }

  rule auto_accept {
    select when wrangler inbound_pending_subscription_added
    pre {
      attrs = event:attrs.klog("subscription: ");
    }

    if (attrs{"Rx_role"}.lc() == "group") then noop()

    fired {
      raise wrangler event "pending_subscription_approval"
        attributes attrs;
      log info "auto accepted subscription."
    }
  }

  rule group_lights_on {
    select when lutron group_lights_on
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "light") => "lightsOn"
            | (subscriber == "group") => "group_lights_on"
            | "notLight"
    }
    if (type != "notLight" && isConnected()) then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_on",
        "domain": "lutron", "type": type
      })
    notfired {
      raise lutron event "error"
        attributes {"message": "Command Not Sent: Not Logged In"}
          if not isConnected()
    }
  }

  rule group_lights_off {
    select when lutron group_lights_off
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "light") => "lights_off"
            | (subscriber == "group") => "group_lights_off"
            | "notLight"
    }
    if (type != "notLight" && isConnected()) then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_off",
        "domain": "lutron", "type": type
      })
    notfired {
      raise lutron event "error"
        attributes {"message": "Command Not Sent: Not Logged In"}
          if not isConnected()
    }
  }

  rule group_lights_brightness {
    select when lutron group_lights_brightness
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "light") => "set_brightness"
            | (subscriber == "group") => "group_lights_brightness"
            | "notLight"
    }
    if (type != "notLight" && isConnected()) then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_brightness",
        "domain": "lutron", "type": type,
        "attrs": event:attrs
      })
    notfired {
      raise lutron event "error"
        attributes {"message": "Command Not Sent: Not Logged In"}
          if not isConnected()
    }
  }

  rule group_lights_flash {
    select when lutron group_lights_flash
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "light") => "flash"
            | (subscriber == "group") => "group_lights_flash"
            | "notLight"
    }
    if (type != "notLight" && isConnected()) then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_flash",
        "domain": "lutron", "type": type,
        "attrs": event:attrs
      })
    notfired {
      raise lutron event "error"
        attributes {"message": "Command Not Sent: Not Logged In"}
          if not isConnected()
    }
  }

  rule group_lights_stop_flash {
    select when lutron group_lights_stop_flash
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "light") => "stop_flash"
            | (subscriber == "group") => "group_lights_stop_flash"
            | "notLight"
    }
    if (type != "notLight" && isConnected()) then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_stop_flash",
        "domain": "lutron", "type": type
      })
    notfired {
      raise lutron event "error"
        attributes {"message": "Command Not Sent: Not Logged In"}
          if not isConnected()
    }
  }

  rule group_shades_open {
    select when lutron group_shades_open
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "shade") => "shades_open"
            | (subscriber == "group") => "group_shades_open"
            | "notShade"
    }
    if (type != "notShade" && isConnected()) then
    event:send(
      {
        "eci": Tx, "eid": "group_shades_open",
        "domain": "lutron", "type": type,
        "attrs": event:attrs
      })
    notfired {
      raise lutron event "error"
        attributes {"message": "Command Not Sent: Not Logged In"}
          if not isConnected()
    }
  }

  rule group_shades_close {
    select when lutron group_shades_close
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "shade") => "shades_close"
            | (subscriber == "group") => "group_shades_close"
            | "notShade"
    }
    if (type != "notShade" && isConnected()) then
    event:send(
      {
        "eci": Tx, "eid": "group_shades_close",
        "domain": "lutron", "type": type
      })
    notfired {
      raise lutron event "error"
        attributes {"message": "Command Not Sent: Not Logged In"}
          if not isConnected()
    }
  }
}
