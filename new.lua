-- AO Process for IoT Communication
-- Process ID: jDIsVeRE7-rW5fBvCMYB05e4mnQWXWw-lvtTAb-EG9w
-- This process receives messages from the mother process and sends responses via HTTP

local json = require("json")
local http = require("http")

-- Configuration
local AO_TO_IOT_SERVER = "57.128.58.120" -- Replace with your server's IP
local DEFAULT_RESPONSE_TOPIC = "iot/response/esp8266"

-- Initialize state
if not ao.state then
  ao.state = {
    messageCount = 0,
    lastMessage = "",
    deviceTopics = {}
  }
end

-- Helper function to send HTTP POST request to the Express server
function sendToIoT(topic, data)
  print("Sending message to IoT via Express server")
  print("Topic: " .. topic)
  print("Data: " .. (type(data) == "string" and data or json.encode(data)))
  
  -- Format request payload
  local payload = json.encode({
    ["route-to-publish"] = topic,
    ["data"] = data
  })
  
  -- Send HTTP POST request
  local response = http.post(AO_TO_IOT_SERVER, payload, {
    ["Content-Type"] = "application/json"
  })
  
  if response and response.status == 200 then
    print("Successfully sent message to IoT server: " .. (response.body or "No response body"))
    return true
  else
    print("Failed to send message to IoT server: " .. (response and response.status or "No response"))
    if response and response.body then
      print("Error: " .. response.body)
    end
    return false
  end
end

-- Handler for IoT messages coming from the mother process
Handlers.add(
  "IoT-Message-Handler",
  { Action = "IoT-Message" },
  function (msg)
    print("Received IoT message from mother process: " .. msg.Data)
    ao.state.messageCount = ao.state.messageCount + 1
    ao.state.lastMessage = msg.Data
    
    -- Get the response topic from tags
    local responseTopic = msg.Tags["Response-Topic"]
    if responseTopic then
      -- Store the topic for this device for future use
      ao.state.deviceTopics[msg.Id] = responseTopic
      
      -- Send a ping response back to the IoT device
      local success = sendToIoT(responseTopic, "ping")
      
      if success then
        return "Sent ping to IoT device on topic: " .. responseTopic
      else
        return "Failed to send ping to IoT device"
      end
    else
      print("No response topic found in message tags")
      return "Error: No response topic provided"
    end
  end
)

-- Handler for direct messages (no Action tag)
Handlers.add(
  "Direct-Message-Handler",
  function(msg)
    -- Return true if msg has no Action or it's not IoT-Message
    return not msg.Action or msg.Action ~= "IoT-Message"
  end,
  function(msg)
    print("Received direct message: " .. (msg.Data or "no data"))
    
    -- If we don't have a response topic in the tags, try to use DEFAULT_RESPONSE_TOPIC
    local responseTopic = DEFAULT_RESPONSE_TOPIC
    
    -- Send a generic response to the default topic
    sendToIoT(responseTopic, {
      ["type"] = "response",
      ["messageId"] = msg.Id,
      ["timestamp"] = os.time(),
      ["message"] = "Received your direct message"
    })
    
    return "Processed direct message and sent response to default topic"
  end
)

-- Debug handler to get process status
Handlers.add(
  "Status-Handler",
  { Action = "Status" },
  function(msg)
    return json.encode({
      processId = "jDIsVeRE7-rW5fBvCMYB05e4mnQWXWw-lvtTAb-EG9w",
      messageCount = ao.state.messageCount,
      lastMessage = ao.state.lastMessage,
      deviceTopics = ao.state.deviceTopics
    })
  end
)

-- Echo handler to test the Express server connection
Handlers.add(
  "Echo-Handler",
  { Action = "Echo" },
  function(msg)
    local topic = msg.Tags["Topic"] or DEFAULT_RESPONSE_TOPIC
    local data = msg.Data or "echo test"
    
    local success = sendToIoT(topic, data)
    
    if success then
      return "Echo sent to topic " .. topic .. ": " .. data
    else
      return "Failed to send echo"
    end
  end
)

print("AO Process for IoT Communication initialized!")
print("HTTP server endpoint: " .. AO_TO_IOT_SERVER)
print("Default response topic: " .. DEFAULT_RESPONSE_TOPIC)