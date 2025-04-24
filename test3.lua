-- ESP8266 Response Process - Version 3
-- Process ID: jDIsVeRE7-rW5fBvCMYB05e4mnQWXWw-lvtTAb-EG9w
local json = require("json")

-- Mother process ID
local MOTHER_PROCESS_ID = "PQXER2h3iVQuB2GgDrElFh70Rbvli_ndRRWMkLooR7M"

-- Initialize state
if not ao.state then
  ao.state = {
    messageCount = 0,
    lastResponse = ""
  }
end

-- Debug helper function to print all message details
function printMessage(msg)
  print("=== MESSAGE DETAILS ===")
  print("ID: " .. (msg.Id or "none"))
  print("Owner: " .. (msg.Owner or "none"))
  print("Target: " .. (msg.Target or "none"))
  print("Data: " .. (msg.Data or "none"))
  
  print("Tags:")
  if msg.Tags then
    for name, value in pairs(msg.Tags) do
      print("  " .. name .. ": " .. value)
    end
  else
    print("  No tags")
  end
  
  print("Action: " .. (msg.Action or "none"))
  print("======================")
end

-- Handle ANY message, then inspect it
Handlers.add(
  "Message-Inspector",
  function(msg)
    printMessage(msg) -- Print all message details for debugging
    return true
  end,
  function(msg)
    ao.state.messageCount = ao.state.messageCount + 1
    print("Message #" .. ao.state.messageCount .. " received")
    
    -- Try to get the response topic from the message
    local responseTopic = nil
    
    -- Check in Tags first
    if msg.Tags and msg.Tags["Response-Topic"] then
      responseTopic = msg.Tags["Response-Topic"]
      print("Found Response-Topic in Tags: " .. responseTopic)
    end
    
    -- If we don't have a response topic yet, try to extract from the Data
    if not responseTopic and msg.Data then
      -- Try to parse the data as JSON
      local success, data = pcall(json.decode, msg.Data)
      if success and data["where-to-find-me"] then
        responseTopic = data["where-to-find-me"]
        print("Found where-to-find-me in Data JSON: " .. responseTopic)
      end
    end
    
    -- If we found a response topic, send a ping
    if responseTopic then
      print("Sending ping to: " .. responseTopic)
      
      local pingData = json.encode({
        topic = responseTopic,
        message = "ping"
      })
      
      print("Ping data: " .. pingData)
      
      -- Send the ping through the mother process
      ao.send({
        Target = MOTHER_PROCESS_ID,
        Action = "Send-To-IoT",
        Data = pingData
      })
      
      ao.state.lastResponse = "Sent ping to " .. responseTopic
      return "Sent ping to " .. responseTopic
    else
      print("No response topic found in message")
      ao.state.lastResponse = "No response topic found"
      return "No response topic found"
    end
  end
)

print("ESP8266 Process initialized! Mother Process ID: " .. MOTHER_PROCESS_ID)