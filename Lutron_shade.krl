ruleset Lutron_shade {
  meta {
    shares __testing
  }

  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "lutron", "type": "shadeOpen" },
                              { "domain": "lutron", "type": "shadeClose" } ] }
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

  rule Send_Command_shadeOpen {
    select when lutron shadeOpen
    pre {
      command = "#SHADEGRP," + ent:IntegrationID + ",1,100"
    }
    telnet:sendCMD(command)
  }

  rule Send_Command_shadeClose {
    select when lutron shadeClose
    pre {
      command = "#SHADEGRP," + ent:IntegrationID + ",1,0"
    }
    telnet:sendCMD(command)
  }
}
