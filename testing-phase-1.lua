-- Target AO Process - LED Blink Handler
-- Load this into your target AO process

-- Check if JSON library exists and load it
if not json then
    json = require("json")
  end
  
  -- Debug handler to catch all messages (for troubleshooting)
  Handlers.add(
    "Debug-Logger",
    function (msg)
      -- This catches ALL messages and logs them, but passes them on to other handlers
      print("DEBUG: Received message:")
      print("DEBUG: Action = " .. (msg.Action or "None"))
      print("DEBUG: From = " .. (msg.From or "Unknown"))
      print("DEBUG: Data = " .. (msg.Data or "Empty"))
      
      -- Print all tags
      print("DEBUG: Tags:")
      if msg.Tags then
        for name, value in pairs(msg.Tags) do
          print("DEBUG:   " .. name .. " = " .. value)
        end
      end
      
      -- Return false to let other handlers process the message
      return false
    end,
    function (msg)
      -- This won't be called since we return false above
      return "Debug only"
    end
  )
  
  -- Handler for IoT messages
  Handlers.add(
    "IoT-Message-Handler",
    { Action = "IoT-Message" },
    function (msg)
      print("Received IoT message: " .. msg.Data)
      
      -- Extract response topic from tags
      local responseTopic = msg.Tags["Response-Topic"]
      if not responseTopic then
        print("ERROR: No Response-Topic tag found")
        return "Error: No Response-Topic tag"
      end
      
      print("Response topic: " .. responseTopic)
      
      -- Build blink command response
      local response = {
        command = "blink",
        count = 3,  -- Changed from "repeat" to "count" to avoid Lua keyword
        message = "Blinking LED in response to: " .. msg.Data,
        timestamp = os.time()
      }
      
      -- Send response back to mother process
      local motherProcess = msg.Tags["Mother-Process"] or msg.From
      print("Sending blink command to mother process: " .. motherProcess)
      
      ao.send({
        Target = motherProcess,
        Action = "Process-Response",
        Data = json.encode(response),
        Tags = {
          ["Response-Topic"] = responseTopic
        }
      })
      
      return "Processed IoT message and sent blink command"
    end
  )
  
  -- This enables the process to accept messages 
  -- Make sure you add this Authority tag to your process
  if not Handlers.exists("AuthorityChecker") then
    Handlers.add(
      "AuthorityChecker", 
      function(msg)
        -- The following MU is authorized
        local authorizedMUs = {
          "fcoN_xJeisVsPXA-trzVAuIiqO3ydLQxM-L4XbrQKzY" -- legacynet MU wallet
        }
        
        -- Return false to allow other handlers to process the message
        return false
      end,
      function(msg)
        -- This won't be called since we return false above
        return "Authority check only"
      end
    )
  end
  
  print("Target Process Blink Handler loaded successfully!")