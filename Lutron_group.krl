ruleset Lutron_group {
  meta {
    use module io.picolabs.subscription alias subscription
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
        { "domain": "lutron", "type": "groupShadesOpen", "attrs": [ "percentage" ] },
        { "domain": "lutron", "type": "groupShadesClose" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
  }

  rule groupLightsOn {
    select when lutron groupLightsOn
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
    }
    if (subscription{"Tx_role"} == "light") then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_on",
        "domain": "lutron", "type": "lightsOn"
      })
  }

  rule groupLightsOff {
    select when lutron groupLightsOff
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
    }
    if (subscription{"Tx_role"} == "light") then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_off",
        "domain": "lutron", "type": "lightsOff"
      })
  }

  rule groupLightsBrightness {
    select when lutron groupLightsBrightness
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
    }
    if (subscription{"Tx_role"} == "light") then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_brightness",
        "domain": "lutron", "type": "setBrightness",
        "attrs": event:attrs
      })
  }

  rule groupLightsFlash {
    select when lutron groupLightsFlash
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
    }
    if (subscription{"Tx_role"} == "light") then
    event:send(
      {
        "eci": Tx, "eid": "group_lights_flash",
        "domain": "lutron", "type": "flash",
        "attrs": event:attrs
      })
  }

  rule groupShadesOpen {
    select when lutron groupShadesOpen
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
    }
    if (subscription{"Tx_role"} == "shade") then
    event:send(
      {
        "eci": Tx, "eid": "group_shades_open",
        "domain": "lutron", "type": "shadesOpen",
        "attrs": event:attrs
      })
  }

  rule groupShadesClose {
    select when lutron groupShadesClose
    foreach subscription:established() setting(subscription)
    pre {
      Tx = subscription{"Tx"}
    }
    if (subscription{"Tx_role"} == "shade") then
    event:send(
      {
        "eci": Tx, "eid": "group_shades_close",
        "domain": "lutron", "type": "shadesClose"
      })
  }
}
