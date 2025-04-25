local json = require("json")

local MOTHER_ID = "vQjIrXpVhBBawZd9SVgsm1FdWR2Gh-MwnaL-WuOtJyQ" -- Change if needed
local TARGET_ALTITUDE = 7

Handlers.add(
  "HandleTelemetry",
  {
    Action = "Route-IoT-Message"
  },
  function (msg)
    print("📡 Received drone telemetry:", msg.Data)

    local ok, data = pcall(function() return json.decode(msg.Data) end)
    if not ok or not data or not data.data then
      print("❌ Invalid or missing telemetry")
      return
    end

    local alt = tonumber(data.data.altitude or 0)
    print("🔍 Evaluating flight data...")
    print("📶 Altitude:", alt)

    local response
    if alt >= TARGET_ALTITUDE * 0.95 then
      print("✅ Decision: Target altitude reached!")
      response = {
        topic = data["where-to-find-me"] or "esp/debug",
        data = {
          decision = "✅ Target altitude reached!",
          altitude = alt,
          note = "Simulated AO Decision"
        }
      }
    elseif alt < 1 then
      print("🛬 Decision: Drone has landed.")
      response = {
        topic = data["where-to-find-me"] or "esp/debug",
        data = {
          decision = "🛬 Drone has landed.",
          altitude = alt,
          note = "Simulated AO Decision"
        }
      }
    else
      print("📊 Altitude stable, no action.")
      return
    end

    ao.send({
      Target = MOTHER_ID,
      Action = "IOT-REPLY",
      Data = json.encode(response)
    })
  end
)

print("🧠 AO drone logic process loaded.")
