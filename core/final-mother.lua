-- Mother Process for IoT-AO Routing
-- This process receives messages from IoT devices via the router
-- and distributes them to the specified AO processes

local json = require("json")

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
      return "Error parsing JSON data"
    end
    
    -- Extract the list of AO processes to forward to
    local aoProcesses = iotData["ao-processes"]
    if not aoProcesses then
      print("No ao-processes field found in message")
      return "Missing ao-processes field"
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
      
      -- Send message to target process
      ao.send({
        Target = processId,
        Action = "IoT-Message",
        Data = iotData.data,
        Tags = {
          ["Source-Topic"] = MQTT_SUBSCRIBE_TOPIC,
          ["Response-Topic"] = iotData["where-to-find-me"]
        }
      })
      
      -- Add to responses table
      table.insert(responses, {
        process = processId,
        status = "message_sent"
      })
    end
    
    -- Send response back to the router
    local responseJson = json.encode({
      topic = iotData["where-to-find-me"],
      data = {
        status = "ok",
        message = "Message routed to " .. #processIds .. " processes",
        processes = responses
      }
    })
    
    print("Sending response: " .. responseJson)
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
    print("Received unknown message type")
    return json.encode({
      status = "error",
      message = "Unknown message type"
    })
  end
)

print("Mother Process loaded successfully!")