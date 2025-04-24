Handlers.add("onMessage", { Action = "Ping" }, function(msg)
    local payload = msg.Data
    if type(payload) == "table" and payload.payload then
      print("ESP said: " .. tostring(payload.payload))
    else
      print("ESP said: " .. tostring(payload))
    end
  
    msg:reply({
      Tags = {
        ["Action"] = "Blink",
        ["Target-MQTT-Channel"] = "esp/response"
      },
      Data = "blink"
    })
  end)
  