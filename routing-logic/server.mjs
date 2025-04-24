const express = require('express');
const mqtt = require('mqtt');
const { createDataItemSigner, message, result } = require('@permaweb/aoconnect');
const fs = require('fs');

// Create Express app
const app = express();

// MQTT connection options - no auth with actual server IP
const mqttOptions = {
  host: 'localhost', // Using the provided static IP
  port: 1883,
  clientId: 'ExpressServer_' + Math.random().toString(16).substr(2, 8)
};

// MQTT topics
const subscribeTopic = 'root/true';
const publishTopic = 'command/blink';

// Path to wallet file
const walletPath = './wallet.json';

// Function to send a message to AO process and wait for response
async function sendToAOProcess(aoAddress, data) {
  try {
    // Check if wallet file exists
    if (!fs.existsSync(walletPath)) {
      console.error('Wallet file not found. Please create a wallet file at:', walletPath);
      return;
    }

    const wallet = JSON.parse(fs.readFileSync(walletPath).toString());

    console.log(`Sending message to AO process: ${aoAddress}`);
    console.log(`Message data: ${data}`);

    // Send message to AO process
    const messageResult = await message({
      process: aoAddress,
      tags: [
        { name: "Action", value: "Message-From-MQTT" }
],
      signer: createDataItemSigner(wallet),
      data: data
    });

    console.log('Message sent to AO process successfully:', messageResult);

    // Wait a moment for the message to be processed
    console.log('Waiting for response from AO process...');

    // Get the result from the process (this is the response)
    setTimeout(async () => {
      try {
        const processResult = await result({
          message: messageResult,
          process: aoAddress
        });

        console.log('Received result from AO process:', processResult);

        // Check if we have output to handle
        if (processResult && processResult.Output) {
          try {
            // Parse the output if it's JSON or just use the string
            let response;
            try {
              response = JSON.parse(processResult.Output);
            } catch {
              response = processResult.Output;
            }

            // Create response for ESP8266
            const blinkCommand = {
              'sub-id': publishTopic,
              'data': 'blink'
            };

            // Publish blink command to MQTT
            console.log('Publishing blink command to MQTT:', blinkCommand);
            mqttClient.publish(publishTopic, JSON.stringify(blinkCommand));
          } catch (parseError) {
console.error('Error parsing process result:', parseError);
          }
        }
      } catch (resultError) {
        console.error('Error getting result from AO process:', resultError);
      }
    }, 2000); // Give the process 2 seconds to respond

    return messageResult;
  } catch (error) {
    console.error('Error sending message to AO process:', error);
    return null;
  }
}

// Connect to MQTT broker
const mqttClient = mqtt.connect(mqttOptions);

// MQTT connection event
mqttClient.on('connect', function() {
  console.log('Connected to MQTT broker');
  mqttClient.subscribe(subscribeTopic, function(err) {
    if (!err) {
      console.log(`Subscribed to ${subscribeTopic}`);
    } else {
      console.error('Subscription error:', err);
    }
  });
});

// MQTT message event - process JSON and forward to AO
mqttClient.on('message', function(topic, message) {
  console.log(`Received message on ${topic}: ${message.toString()}`);

  try {
    // Parse JSON message
    const jsonMessage = JSON.parse(message.toString());

    // Check if message contains aoaddress and data
    if (jsonMessage.aoaddress && jsonMessage.data) {
      console.log(`Forwarding message to AO process: ${jsonMessage.aoaddress}`);
      // Send message to AO process
      sendToAOProcess(jsonMessage.aoaddress, jsonMessage.data);
    } else {
      console.log('Message does not contain required aoaddress and data fields');
    }
  } catch (error) {
    console.error('Error processing MQTT message:', error);
  }
});

// MQTT error event
mqttClient.on('error', function(error) {
  console.error('MQTT Error:', error);
});

// Basic health endpoint
app.get('/', (req, res) => {
  const status = {
    status: 'running',
    subscribing_to: subscribeTopic,
    publishing_to: publishTopic,
    ao_process: 'yL4viBzzGy3zb7rmbf48EfhjiAnvqFaCAa9qptcBzWE'
  };
  res.json(status);
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Express server running on port ${PORT}`);
});
                                   