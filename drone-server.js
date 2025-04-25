const express = require('express');
const mqtt = require('mqtt');
const { createDataItemSigner, message } = require('@permaweb/aoconnect');
const fs = require('fs');

// Create Express app
const app = express();

// Configuration
const MQTT_BROKER = '57.128.58.120';
const MQTT_PORT = 1883;
const MQTT_SUBSCRIBE_TOPIC = 'root/main';
const MOTHER_PROCESS_ID = '5H8rZ5boAX-9VvWl5w0z_VmjkAuRbmCdvat5qfZ8UxY';
const WALLET_PATH = './wallet.json';
const TARGET_ALTITUDE = 4.9; // meters

// Load wallet
if (!fs.existsSync(WALLET_PATH)) {
  console.error('ERROR: Wallet file not found at', WALLET_PATH);
  process.exit(1);
}

let wallet;
try {
  wallet = JSON.parse(fs.readFileSync(WALLET_PATH).toString());
  console.log('✅ Wallet loaded successfully');
} catch (error) {
  console.error('ERROR: Failed to load wallet:', error.message);
  process.exit(1);
}

// MQTT setup
const mqttOptions = {
  host: MQTT_BROKER,
  port: MQTT_PORT,
  clientId: 'AO_Router_' + Math.random().toString(16).substr(2, 8)
};

const mqttClient = mqtt.connect(mqttOptions);

// Send data to mother process
async function sendToMotherProcess(iotData) {
  try {
    console.log(`📡 Live stream to AO → ${MOTHER_PROCESS_ID}`);
    await message({
      process: MOTHER_PROCESS_ID,
      tags: [{ name: "Action", value: "Route-IoT-Message" }],
      signer: createDataItemSigner(wallet),
      data: JSON.stringify(iotData)
    });
  } catch (error) {
    console.error('❌ Failed to send live stream to AO:', error.message);
  }
}

// Altitude tracking state
let hasReachedAltitude = false;
let hasLanded = false;

// MQTT events
mqttClient.on('connect', () => {
  console.log(`✅ Connected to MQTT broker at ${MQTT_BROKER}:${MQTT_PORT}`);
  mqttClient.subscribe(MQTT_SUBSCRIBE_TOPIC, (err) => {
    if (err) {
      console.error('❌ MQTT subscription error:', err.message);
    } else {
      console.log(`📡 Subscribed to topic: ${MQTT_SUBSCRIBE_TOPIC}`);
    }
  });
});

mqttClient.on('message', (topic, message) => {
  console.log(`📨 Message on ${topic}: ${message.toString()}`);
  try {
    const iotData = JSON.parse(message.toString());
    const altitude = iotData?.data?.altitude;
    const responseTopic = iotData["where-to-find-me"] || "esp/response";

    // ✅ Send to AO always
    sendToMotherProcess(iotData);

    if (typeof altitude === 'number') {
      console.log(`📡 Telemetry -> Altitude: ${altitude.toFixed(2)} meters`);

      if (!hasReachedAltitude && altitude >= TARGET_ALTITUDE * 0.95) {
        hasReachedAltitude = true;
        hasLanded = false;

        setTimeout(() => {
          console.log("📬 AO says: ✅ Target altitude reached!");
          const response = {
            decision: "✅ Target altitude reached!",
            altitude,
            note: "Action computed by AO"
          };
          mqttClient.publish(responseTopic, JSON.stringify(response));
          console.log(`📤 Published on ${responseTopic}:`, response);
        }, 2000);
      }

      if (!hasLanded && hasReachedAltitude && altitude < 1) {
        hasLanded = true;

        setTimeout(() => {
          console.log("📬 AO says: 🛬 Landing complete.");
          const landingMsg = {
            decision: "🛬 Drone has landed.",
            altitude,
            note: "AO confirms successful landing"
          };
          mqttClient.publish(responseTopic, JSON.stringify(landingMsg));
          console.log(`📤 Published on ${responseTopic}:`, landingMsg);
        }, 2000);
      }
    }
  } catch (error) {
    console.error('❌ Error processing MQTT message:', error.message);
  }
});

// Health endpoint
app.get('/', (req, res) => {
  res.json({
    status: 'running',
    mqtt_broker: MQTT_BROKER,
    subscribed_topic: MQTT_SUBSCRIBE_TOPIC,
    mother_process: MOTHER_PROCESS_ID
  });
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 IoT-AO Router running on port ${PORT}`);
});
