
```markdown
# 🌐 AURA – IoT ↔ AO Routing Framework

AURA is a real-time routing framework that connects your IoT devices to the Arweave AO compute network. It enables **two-way communication** between your devices and decentralized processes, allowing you to send data to AO and receive intelligent responses back — effortlessly.

The server and AO mother process are already deployed. All you have to do is plug in your IoT device and start publishing MQTT messages in the correct format.

---

## ⚙️ MQTT Configuration

- **Broker IP:** `57.128.58.120`
- **Port:** `1883`
- **Publish Topic:** `root/main`
- **Subscribe Topic:** your choice (set using `"where-to-find-me"` field)

---

## 💬 Message Format (IoT → AO)

Your IoT device should publish a message to topic `root/main` with the following structure:

```json
{
  "ao-processes": "PROCESS_ID_1,PROCESS_ID_2",
  "data": "your payload or sensor data",
  "where-to-find-me": "your/device/response/topic"
}
```

### Field Description:

- **ao-processes**: Comma-separated list of AO process IDs you want to message
- **data**: The payload you want to send (string or structured JSON)
- **where-to-find-me**: The MQTT topic where your device will receive the AO response

---

## 🔁 How AURA Works (Bidirectional Flow)

1. IoT device sends a message to `root/main` with the required fields.
2. AURA Express server receives it and forwards it to the deployed AO Mother Process.
3. The Mother Process routes the message to each AO process specified in `ao-processes`.
4. AO process handles the message and replies with its output.
5. AURA server picks up the AO response and publishes it back to the topic given in `where-to-find-me`.
6. Your device, subscribed to `where-to-find-me`, receives the AO result in real time.

---

## 📬 Full Example

### Device publishes:

```json
{
  "ao-processes": "a1b2c3d4e5",
  "data": "temperature=28.7",
  "where-to-find-me": "esp32/sensor/response"
}
```

### AO Process receives:

```lua
-- Sample AO process
Handlers.add("from-iot", { Action = "IoT-Message" }, function(msg)
  print("Received from IoT: " .. tostring(msg.Data))

  msg:reply({
    Tags = {
      ["Target-MQTT-Channel"] = msg.Tags["Response-Topic"]
    },
    Data = "Activate fan"
  })
end)

return { Output = { data = "ready" } }
```

### Device receives (on `esp32/sensor/response`):

```json
{
  "status": "ok",
  "message": "Activate fan"
}
```

---

## 🧠 AO Lua Process Template

This is the Lua code you can use inside any AO process to receive and reply to messages from IoT devices:

```lua
Handlers.add("from-iot", { Action = "IoT-Message" }, function(msg)
  print("Received from IoT: " .. tostring(msg.Data))

  msg:reply({
    Tags = {
      ["Target-MQTT-Channel"] = msg.Tags["Response-Topic"]
    },
    Data = "Processed: " .. tostring(msg.Data)
  })
end)

return { Output = { data = "ready" } }
```

---

## 📌 Recap

| Direction        | Action                                          | Protocol |
|------------------|--------------------------------------------------|----------|
| IoT → AO         | Publish JSON to `root/main`                      | MQTT     |
| AO → IoT         | AO process replies → Server routes via MQTT      | MQTT     |
| Device receives  | On the topic given in `where-to-find-me`         | MQTT     |

---

## 🛠 Deployment Status

- ✅ Express routing server: **Deployed**
- ✅ AO Mother Process: **Deployed**
- ✅ MQTT Broker: **Live at 57.128.58.120:1883**

You only need to:
- Connect your IoT device to the broker
- Format your messages correctly
- Handle responses on your device

---

## 🤝 Credits

Built with ❤️ by the AURA Team  
Powered by: MQTT • Arweave AO • Node.js • Lua

---

## 🧪 Coming Soon

- Dashboards for monitoring
- Templates for ESP32/Arduino
- Live process registration

Stay tuned!
```

---

✅ You can now **copy-paste** this as your repo’s `README.md`. Let me know if you want a `LICENSE`, `CONTRIBUTING.md`, or sample `.ino` device file next.
