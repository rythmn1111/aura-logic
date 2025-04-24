-- Mother Process for IoT-AO Routing
-- This process receives messages from IoT devices via the router
-- and distributes them to the specified AO processes

-- Check if JSON library exists and load it
if not json then
    json = require("json")
  end
  
  -- Handler for IoT messages coming from the Express router
  Handlers.add(
    "IoT-Router",
    { Action = "Route-IoT-Message" },
    function (msg)
      print("Received message from IoT router: " .. msg.Data)
      
      -- Parse the JSON data
      local success, iotData = pcall(json.decode, msg.Data)
      if not success then
        print("Error parsing JSON data: " .. iotData)
        return json.encode({
          status = "error",
          message = "Error parsing JSON data"
        })
      end
      
      -- Extract the list of AO processes to forward to
      local aoProcesses = iotData["ao-processes"]
      if not aoProcesses then
        print("No ao-processes field found in message")
        return json.encode({
          status = "error",
          message = "Missing ao-processes field"
        })
      end
      
      -- Split comma-separated process IDs
      local processIds = {}
      for processId in string.gmatch(aoProcesses, "([^,]+)") do
        -- Trim whitespace
        processId = processId:match("^%s*(.-)%s*$")
        table.insert(processIds, processId)
      end
      
      print("Forwarding message to " .. #processIds .. " processes")
      
      -- Forward message to each process
      local responses = {}
      for _, processId in ipairs(processIds) do
        print("Sending to process: " .. processId)
        
        -- Include some debugging to verify the send operation
        local success, err = pcall(function()
          ao.send({
            Target = processId,
            Action = "IoT-Message", -- This must match what the target process expects
            Data = iotData.data,
            Tags = {
              ["Source-Topic"] = "root/main",
              ["Response-Topic"] = iotData["where-to-find-me"],
              ["Mother-Process"] = ao.id
            }
          })
        end)
        
        local status = success and "message_sent" or "send_error"
        local errorMsg = not success and tostring(err) or nil
        
        -- Add to responses table
        table.insert(responses, {
          process = processId,
          status = status,
          error = errorMsg
        })
        
        if not success then
          print("ERROR sending to process " .. processId .. ": " .. tostring(err))
        else
          print("Message sent successfully to process " .. processId)
        end
      end
      
      -- Send response back to the router
      local responseData = {
        topic = iotData["where-to-find-me"],
        data = {
          status = "ok",
          message = "Message routed to " .. #processIds .. " processes",
          processes = responses
        }
      }
      
      local responseJson = json.encode(responseData)
      print("Sending response: " .. responseJson)
      return responseJson
    end
  )
  
  -- Handler for responses from target AO processes
  Handlers.add(
    "Process-Response",
    { Action = "Process-Response" },
    function (msg)
      print("Received response from target process: " .. msg.From)
      
      -- Parse the response data
      local success, responseData = pcall(json.decode, msg.Data)
      if not success then
        print("Error parsing response data: " .. responseData)
        return json.encode({
          status = "error",
          message = "Error parsing response data"
        })
      end
      
      -- Find the response topic
      local responseTopic = msg.Tags["Response-Topic"]
      if not responseTopic then
        print("No Response-Topic tag found")
        return json.encode({
          status = "error",
          message = "Missing Response-Topic tag"
        })
      end
      
      -- Format response for sending back to IoT device
      local mqttResponse = {
        topic = responseTopic,
        data = responseData
      }
      
      local responseJson = json.encode(mqttResponse)
      print("Forwarding response to IoT device: " .. responseJson)
      return responseJson
    end
  )
  
  -- Default handler for any other messages
  Handlers.add(
    "Default-Handler",
    function (msg)
      return true  -- Match any message
    end,
    function (msg)
      print("Received unknown message type: " .. (msg.Action or "No Action"))
      print("From: " .. (msg.From or "Unknown"))
      print("Data: " .. (msg.Data or "None"))
      
      -- Print all tags
      print("Tags:")
      if msg.Tags then
        for name, value in pairs(msg.Tags) do
          print("  " .. name .. " = " .. value)
        end
      end
      
      return json.encode({
        status = "error",
        message = "Unknown message type"
      })
    end
  )
  
  print("Mother Process loaded successfully!")