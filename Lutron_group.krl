ruleset Lutron_group {
  meta {
    use module io.picolabs.subscription alias subscription
    use module io.picolabs.wrangler alias wrangler
    shares __testing
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ { "domain": "lutron", "type": "groupLightsOn" },
        { "domain": "lutron", "type": "groupLightsOff" },
        { "domain": "lutron", "type": "groupLightsBrightness", "attrs": [ "brightness" ] },
        { "domain": "lutron", "type": "groupLightsFlash", "attrs": [ "fade_time", "delay" ] },
        { "domain": "lutron", "type": "groupLightsStopFlash" },
        { "domain": "lutron", "type": "groupShadesOpen", "attrs": [ "percentage" ] },
        { "domain": "lutron", "type": "groupShadesClose" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
  }

  rule autoAccept {
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

  rule groupLightsOn {
    select when lutron groupLightsOn
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "light") => "lightsOn"
            | (subscriber == "group") => "groupLightsOn"
            | "notLight"
    }
    if not (type == "notLight") then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_on",
        "domain": "lutron", "type": type
      })
  }

  rule groupLightsOff {
    select when lutron groupLightsOff
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "light") => "lightsOff"
            | (subscriber == "group") => "groupLightsOff"
            | "notLight"
    }
    if not (type == "notLight") then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_off",
        "domain": "lutron", "type": type
      })
  }

  rule groupLightsBrightness {
    select when lutron groupLightsBrightness
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "light") => "setBrightness"
            | (subscriber == "group") => "groupLightsBrightness"
            | "notLight"
    }
    if not (type == "notLight") then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_brightness",
        "domain": "lutron", "type": type,
        "attrs": event:attrs
      })
  }

  rule groupLightsFlash {
    select when lutron groupLightsFlash
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "light") => "flash"
            | (subscriber == "group") => "groupLightsFlash"
            | "notLight"
    }
    if not (type == "notLight") then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_flash",
        "domain": "lutron", "type": type,
        "attrs": event:attrs
      })
  }

  rule groupLightsStopFlash {
    select when lutron groupLightsStopFlash
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "light") => "stopFlash"
            | (subscriber == "group") => "groupLightsStopFlash"
            | "notLight"
    }
    if not (type == "notLight") then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_stop_flash",
        "domain": "lutron", "type": type
      })
  }

  rule groupShadesOpen {
    select when lutron groupShadesOpen
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "shade") => "shadesOpen"
            | (subscriber == "group") => "groupShadesOpen"
            | "notShade"
    }
    if not (type == "notShade") then
    event:send(
      {
        "eci": Tx, "eid": "group_shades_open",
        "domain": "lutron", "type": type,
        "attrs": event:attrs
      })
  }

  rule groupShadesClose {
    select when lutron groupShadesClose
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
      subscriber = subscription{"Tx_role"}.lc()
      type = (subscriber == "shade") => "shadesClose"
            | (subscriber == "group") => "groupShadesClose"
            | "notShade"
    }
    if not (type == "notShade") then
    event:send(
      {
        "eci": Tx, "eid": "group_shades_close",
        "domain": "lutron", "type": type
      })
  }

  rule updateManagerGroupCount {
    select when wrangler deletion_imminent
    event:send(
      {
        "eci": wrangler:parent_eci(), "eid": "decrement_group_count",
        "domain": "lutron", "type": "decrement_group_count"
      })
  }
}
