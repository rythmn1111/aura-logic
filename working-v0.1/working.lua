-- Handler for MQTT messages from ESP8266
-- This will respond to "hello world" messages with a blink command

-- Initialize a variable to track last response time
if not lastMessageTime then
    lastMessageTime = 0
  end
  
  -- Handler for MQTT messages with "Message-From-MQTT" action
  Handlers.add(
    "MQTT-Handler",
    { Action = "Message-From-MQTT" },
    function (msg)
      -- Log the incoming message
      print("Received message from MQTT: " .. msg.Data)
      
      -- Check if the message is "hello world"
      if msg.Data == "hello world" then
        -- Get current time to prevent duplicate responses in quick succession
        local currentTime = os.time()
        
        -- Only respond if at least 10 seconds since last response
        if currentTime - lastMessageTime > 10 then
          lastMessageTime = currentTime
          
          -- Create response JSON with the blink command
          print("Sending blink command response")
          return {
            Output = '{"sub-id": "command/blink", "data": "blink"}'
          }
        else
          print("Ignoring duplicate message (received within 10 seconds)")
          return {
            Output = "Duplicate request ignored"
          }
        end
      else
        -- For any other message content, just echo it back
        return {
          Output = "Echo: " .. msg.Data
        }
      end
    end
  )
  
  -- Log that the handler was successfully loaded
  print("MQTT handler loaded successfully!")