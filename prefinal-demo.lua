local json = require("json")

local MOTHER_ADDRESS = "jgGQFA_H-fmeso4aTR2vNORyVTEx93srK2IuQSdCCLI" -- 🔁 your mother process ID here

Handlers.add(
  "IoT-Forwarder",
  { Action = "IoT-Message" },
  function (msg)
    print("💡 Received message:", msg.Data)

    -- Craft response as simple string
    local payload = {
      ["topic-to-share"] = msg.Tags["Response-Topic"] or "esp/fallback",
      ["data"] = {
        received = msg.Data,
        note = "✅ Direct message from Target"
      }
    }

    ao.send({
      Target = MOTHER_ADDRESS,
      Action = "IOT-REPLY",
      Data = json.encode(payload)
    })

    print("📤 Response forwarded to mother")
  end
)

print("✅ AO target process ready")
