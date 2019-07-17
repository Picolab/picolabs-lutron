ruleset Lutron_group {
  meta {
    use module io.picolabs.subscription alias subscription
    use module io.picolabs.wrangler alias wrangler
    shares __testing, isConnected, devicesAndDetails, getDeviceByName,
          getSubscriptionByTx, subscribers, isSafeToAddGroup, unsafeGroups, unsafeGroupNames
    provides devicesAndDetails
  }
  global {
    __testing = { "queries":
      [ { "name": "isConnected" },
        { "name": "subscribers" },
        { "name": "devicesAndDetails" },
        { "name": "unsafeGroups" },
        { "name": "unsafeGroupNames" },
        { "name": "isSafeToAddGroup", "args": [ "name" ] },
        { "name": "getDeviceByName", "args": [ "name" ] },
        { "name": "getSubscriptionByTx", "args": [ "Tx" ] }
      ] , "events":
      [ { "domain": "lutron", "type": "group_lights_on" },
        { "domain": "lutron", "type": "group_lights_off" },
        { "domain": "lutron", "type": "group_lights_brightness", "attrs": [ "brightness" ] },
        { "domain": "lutron", "type": "group_lights_flash", "attrs": [ "fade_time", "delay" ] },
        { "domain": "lutron", "type": "group_lights_stop_flash" },
        { "domain": "lutron", "type": "group_shades_open", "attrs": [ "percentage" ] },
        { "domain": "lutron", "type": "group_shades_close" },
        { "domain": "lutron", "type": "add_device", "attrs": [ "name" ] },
        { "domain": "lutron", "type": "remove_device", "attrs": [ "name" ] }
      ]
    }

    unsafeGroups = function() {
      ent:unsafe_groups
    }

    unsafeGroupNames = function() {
      unsafeGroups().map(function(x) {
        name = wrangler:skyQuery(x, "io.picolabs.visual_params", "dname");
        [].append(name)
      }).reduce(function(a,b) {
        a.append(b)
      },[])
    }

    isConnected = function() {
      wrangler:skyQuery(wrangler:parent_eci(), "Lutron_manager", "isConnected", null)
    }

    subscribers = function() {
      subscription:established().map(function(x) {
        name = wrangler:skyQuery(x{"Tx"}, "io.picolabs.visual_params", "dname");
        id = wrangler:skyQuery(x{"Tx"}, "io.picolabs.wrangler", "myself"){"id"};
        type = x{"Tx_role"}.lc();
        eci = x{"Tx"};
        {}.put(name, {"id": id, "name": name, "type": type, "eci": eci})
      }).reduce(function(a,b) {
        a.put(b)
      });
    }

    isSafeToAddGroup = function(name) {
      unsafeGroupNames().none(function(x) { x == name })
    }

    devicesAndDetails = function() {
      subscribers = subscription:established().map(function(x) {
        name = wrangler:skyQuery(x{"Tx"}, "io.picolabs.visual_params", "dname");
        id = wrangler:skyQuery(x{"Tx"}, "io.picolabs.wrangler", "myself"){"id"};
        type = x{"Tx_role"}.lc();
        eci = x{"Tx"};
        {}.put(name, {"id": id, "name": name, "type": type, "eci": eci})
      }).reduce(function(a,b) {
        a.put(b)
      });

      lights = subscribers.filter(function(v,k) {
        v{"type"} == "light"
      });

      shades = subscribers.filter(function(v,k) {
        v{"type"} == "shade"
      });

      groups = subscribers.filter(function(v,k) {
        v{"type"} == "group"
      });

      {"lights": lights, "shades": shades, "groups": groups, "unsafeGroups": unsafeGroupNames() }
    }

    getSubscriptionByTx = function(Tx) {
      subscription:established().filter(function(x) {
        x{"Tx"} == Tx
      }).reduce(function(a,b) {
        a.put(b)
      })
    }

    getDeviceByName = function(name) {
      subscribers().filter(function(v,k) {
        v{"name"} == name
      }).values().reduce(function(a,b) {
        a.put(b)
      })
    }
  }

  rule lutron_online {
    select when system online
    fired {
      ent:unsafe_groups := ent:unsafe_groups.defaultsTo([]);
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

  rule on_visual_update {
    select when visual update
    pre {
      dname = event:attr("dname")
      id = wrangler:myself(){"id"}
    }
    if dname then
    event:send(
      {
        "eci": wrangler:parent_eci(), "eid": "child_name_changed",
        "domain": "lutron", "type": "child_name_changed",
        "attrs": {"child_id": id, "child_type": "group", "new_name": dname}
      })
  }

  rule group_lights_on {
    select when lutron group_lights_on
    foreach subscribers() setting(subscriber)
    pre {
      eci = subscriber{"eci"}
      role = subscriber{"type"}
      type = (role == "light") => "lights_on"
            | (role == "group") => "group_lights_on"
            | "notLight"
    }
    if (type != "notLight" && isConnected()) then
    event:send(
      {
        "eci": eci, "eid": "group_lights_on",
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
    foreach subscribers() setting(subscriber)
    pre {
      eci = subscriber{"eci"}
      role = subscriber{"type"}
      type = (role == "light") => "lights_off"
            | (role == "group") => "group_lights_off"
            | "notLight"
    }
    if (type != "notLight" && isConnected()) then
    event:send(
      {
        "eci": eci, "eid": "group_lights_off",
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
    foreach subscribers() setting(subscriber)
    pre {
      eci = subscriber{"eci"}
      role = subscriber{"type"}
      type = (role == "light") => "set_brightness"
            | (role == "group") => "group_lights_brightness"
            | "notLight"
    }
    if (type != "notLight" && isConnected()) then
    event:send(
      {
        "eci": eci, "eid": "group_lights_brightness",
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
    foreach subscribers() setting(subscriber)
    pre {
      eci = subscriber{"eci"}
      role = subscriber{"type"}
      type = (role == "light") => "flash"
            | (role == "group") => "group_lights_flash"
            | "notLight"
    }
    if (type != "notLight" && isConnected()) then
    event:send(
      {
        "eci": eci, "eid": "group_lights_flash",
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
    foreach subscribers() setting(subscriber)
    pre {
      eci = subscriber{"eci"}
      role = subscriber{"type"}
      type = (role == "light") => "stop_flash"
            | (role == "group") => "group_lights_stop_flash"
            | "notLight"
    }
    if (type != "notLight" && isConnected()) then
    event:send(
      {
        "eci": eci, "eid": "group_lights_stop_flash",
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
    foreach subscribers() setting(subscriber)
    pre {
      eci = subscriber{"eci"}
      role = subscriber{"type"}
      type = (role == "shade") => "shades_open"
            | (role == "group") => "group_shades_open"
            | "notShade"
    }
    if (type != "notShade" && isConnected()) then
    event:send(
      {
        "eci": eci, "eid": "group_shades_open",
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
    foreach subscribers() setting(subscriber)
    pre {
      Tx = subscriber{"eci"}
      role = subscriber{"type"}
      type = (role == "shade") => "shades_close"
            | (role == "group") => "group_shades_close"
            | "notShade"
    }
    if (type != "notShade" && isConnected()) then
    event:send(
      {
        "eci": eci, "eid": "group_shades_close",
        "domain": "lutron", "type": type
      })
    notfired {
      raise lutron event "error"
        attributes {"message": "Command Not Sent: Not Logged In"}
          if not isConnected()
    }
  }

  rule track_unsafe_groups {
    select when lutron track_unsafe_groups
    fired {
      ent:unsafe_groups := ent:unsafe_groups.append(event:attr("ecis"))
        .reduce(function(a,b) {
          a.append(b)
        })
    }
  }

  rule filter_unsafe_groups {
    select when lutron filter_unsafe_groups
    foreach subscribers() setting(subscriber)
    pre {
      isGroup = subscriber{"type"} == "group"
    }
    if isGroup then event:send(
      {
        "eci": subscriber{"eci"}, "eid": "filter_unsafe_groups",
        "domain": "lutron", "type": "filter_unsafe_groups",
        "attrs": { "ecis": event:attr("ecis") }
      })
    always {
      ent:unsafe_groups := unsafeGroups().filter(function(x) {
        not (event:attr("ecis") >< x)
      }) on final
    }
  }

  rule add_device {
    select when lutron add_device
    pre {
      name = event:attr("name")
      existing_device = getDeviceByName(name)
      eci = existing_device{"eci"}
      existing_controller = existing_device{"type"} == "controller"
    }
    if isSafeToAddGroup(name) then event:send(
      {
        "eci": wrangler:parent_eci(), "eid": "add_device_to_group",
        "domain": "lutron", "type": "add_device_to_group",
        "attrs": {"device_name": name, "group_name": wrangler:name()}
      })
    fired {
      // to avoid multiple subscriptions to the same group
      raise wrangler event "subscription_cancellation"
        attributes { "Id": getSubscriptionByTx(eci){"Id"} }
        if existing_controller
    }
    else {
      raise lutron event "warning"
        attributes { "message": "unsafe to add group " + name + " (infinite loop warning)" }
    }
  }

  rule add_devices {
    select when lutron add_devices
    foreach (event:attr("devices").split(re#,#)) setting(device)
    pre {
      name = device
    }
    fired {
      raise lutron event "add_device" attributes {"name": name}
    }
  }

  rule remove_device {
    select when lutron remove_device
    pre {
      name = event:attr("name")
      device = getDeviceByName(name).klog("device")
      subscription = getSubscriptionByTx(device{"eci"}).klog("subscription")
      id = subscription{"Id"}
    }
    if (id) then event:send(
      {
        "eci": device{"eci"}, "eid": "filter_unsafe_groups",
        "domain": "lutron", "type": "filter_unsafe_groups",
        "attrs": { "ecis": unsafeGroups().append(wrangler:myself(){"eci"}) }
      })
    fired {
      raise wrangler event "subscription_cancellation"
        attributes { "Id": id }
    }
  }

  rule remove_devices {
    select when lutron remove_devices
    foreach (event:attr("devices").split(re#,#)) setting(device)
    pre {
      name = device
    }
    fired {
      raise lutron event "remove_device"
        attributes { "name": name }
    }
  }
}
