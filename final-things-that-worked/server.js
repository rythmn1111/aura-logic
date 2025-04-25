const express = require('express');
const mqtt = require('mqtt');
const { createDataItemSigner, message, result } = require('@permaweb/aoconnect');
const fs = require('fs');

// Create Express app
const app = express();

// Configuration
const MQTT_BROKER = '57.128.58.120';
const MQTT_PORT = 1883;
const MQTT_SUBSCRIBE_TOPIC = 'root/main';
const MOTHER_PROCESS_ID = 'Pi01pNr1G_p4i0YSYLjl_cgFdrmv4nZolezwxmMffSE';
const WALLET_PATH = './wallet.json';

// Check if wallet exists
if (!fs.existsSync(WALLET_PATH)) {
  console.error('ERROR: Wallet file not found at', WALLET_PATH);
  console.error('Please create a wallet using: npx -y @permaweb/wallet > wallet.json');
  process.exit(1);
}

// Load wallet
let wallet;
try {
  wallet = JSON.parse(fs.readFileSync(WALLET_PATH).toString());
  console.log('Wallet loaded successfully');
} catch (error) {
  console.error('ERROR: Failed to load wallet:', error.message);
  process.exit(1);
}

// MQTT connection options
const mqttOptions = {
  host: MQTT_BROKER,
  port: MQTT_PORT,
  clientId: 'AO_Router_' + Math.random().toString(16).substr(2, 8)
};

// Connect to MQTT broker
const mqttClient = mqtt.connect(mqttOptions);

// Track active processes and response topics
const activeRequests = new Map();

// Function to send message to mother process
async function sendToMotherProcess(iotData) {
  try {
    console.log(`Sending data to mother process: ${MOTHER_PROCESS_ID}`);
    console.log('Data:', iotData);
    
    // Send message to mother process
    const messageResult = await message({
      process: MOTHER_PROCESS_ID,
      tags: [
        { name: "Action", value: "Route-IoT-Message" }
      ],
      signer: createDataItemSigner(wallet),
      data: JSON.stringify(iotData)
    });
    
    console.log('Message sent to mother process successfully:', messageResult);
    
    // Wait for               response
    setTimeout(async () => {
      try {
        const processResult = await result({
          message: messageResult,
          process: MOTHER_PROCESS_ID
        });
        
        console.log('Received result from mother process:', processResult);
        
        // Handle response from mother process
        handleMotherProcessResponse(processResult, iotData);
      } catch (resultError) {
        console.error('Error getting result from mother process:', resultError);
      }
    }, 2000);
    
    return messageResult;
  } catch (error) {
    console.error('Error sending message to mother process:', error);
    return null;
  }
}

// Function to handle responses from the mother process
function handleMotherProcessResponse(processResult, originalRequest) {
  if (!processResult || !processResult.Output) {
    console.log('No valid output from mother process');
    return;
  }
  
  let responseData;
  
  // Try to parse the output as JSON
  try {
    if (typeof processResult.Output === 'string') {
      responseData = JSON.parse(processResult.Output);
    } else if (processResult.Output.data) {
      // Try to extract JSON from the output data if it's an object
      const jsonStr = processResult.Output.data;
      console.log('Extracted data string:', jsonStr);
      
      // Try to find a JSON object in the string
      const jsonMatch = jsonStr.match(/\{\"topic\":.*\}\}/);
      if (jsonMatch) {
        const extractedJson = jsonMatch[0];
        console.log('Extracted JSON:', extractedJson);
        responseData = JSON.parse(extractedJson);
      } else {
        console.log('No JSON pattern found in output data');
        return;
      }
    }
  } catch (error) {
    console.error('Error parsing mother process response:', error);
    return;
  }
  
  if (!responseData) {
    console.log('No valid response data from mother process');
    return;
  }
  
  console.log('Processing response data:', responseData);
  
  // Check if we have a topic to publish to
  const responseTopic = responseData.topic || originalRequest['where-to-find-me'];
  if (!responseTopic) {
    console.log('No response topic specified');
    return;
  }
  
  // Publish the response to the specified topic
  console.log(`Publishing response to ${responseTopic}:`, responseData.data);
  mqttClient.publish(responseTopic, JSON.stringify(responseData.data));
}

// MQTT connection event
mqttClient.on('connect', function() {
  console.log(`Connected to MQTT broker at ${MQTT_BROKER}:${MQTT_PORT}`);
  mqttClient.subscribe(MQTT_SUBSCRIBE_TOPIC, function(err) {
    if (!err) {
      console.log(`Subscribed to ${MQTT_SUBSCRIBE_TOPIC}`);
    } else {
      console.error('Subscription error:', err);
    }
  });
});

// MQTT message event
mqttClient.on('message', function(topic, message) {
  console.log(`Received message on ${topic}: ${message.toString()}`);
  
  try {
    // Parse JSON message
    const iotData = JSON.parse(message.toString());
    
    // Validate required fields
    if (!iotData['ao-processes'] || !iotData['data'] || !iotData['where-to-find-me']) {
      console.error('Message missing required fields (ao-processes, data, where-to-find-me)');
      return;
    }
    
    // Send to mother process
    sendToMotherProcess(iotData);
  } catch (error) {
    console.error('Error processing MQTT message:', error);
  }
});

// MQTT error event
mqttClient.on('error', function(error) {
  console.error('MQTT Error:', error);
});

// MQTT close event
mqttClient.on('close', function() {
  console.log('MQTT connection closed. Attempting to reconnect...');
});

// API endpoints
app.get('/', (req, res) => {
  const status = {
    status: 'running',
    mqtt_broker: MQTT_BROKER,
    subscribing_to: MQTT_SUBSCRIBE_TOPIC,
    mother_process: MOTHER_PROCESS_ID
  };
  res.json(status);
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`IoT-AO Router running on port ${PORT}`);
});