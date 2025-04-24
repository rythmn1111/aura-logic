#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// WiFi credentials - updated with actual values
const char* ssid = "abc";
const char* password = "tcstcstp";

// MQTT Broker settings - updated with actual server IP
const char* mqtt_server = "57.128.58.120";
const int mqtt_port = 1883;
const char* mqtt_publish_topic = "root/true";
const char* mqtt_subscribe_topic = "command/blink";
const char* mqtt_client_id = "ESP8266_Client";

// LED pin - usually GPIO2 which is D4 on most ESP8266 boards
const int ledPin = 2;

// AO process address
const char* ao_process_address = "yL4viBzzGy3zb7rmbf48EfhjiAnvqFaCAa9qptcBzWE";

// Initialize WiFi and MQTT client
WiFiClient espClient;
PubSubClient client(espClient);

// Variables for message timing
unsigned long lastMsgTime = 0;
const long msgInterval = 5000; // Send message every 5 seconds

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

// Callback function for incoming MQTT messages
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  
  // Create a character buffer for the payload
  char message[length + 1];
  for (int i = 0; i < length; i++) {
    message[i] = (char)payload[i];
    Serial.print((char)payload[i]);
  }
  Serial.println();
  message[length] = '\0';
  
  // Parse the JSON message
  StaticJsonDocument<200> doc;
  DeserializationError error = deserializeJson(doc, message);
  
  if (error) {
    Serial.print("deserializeJson() failed: ");
    Serial.println(error.c_str());
    return;
  }
  
  // Check if this is a blink command
  const char* data = doc["data"];
  if (data && strcmp(data, "blink") == 0) {
    Serial.println("Blink command received! Blinking LED 3 times...");
    blinkLED(3);
  }
}

// Function to blink the LED
void blinkLED(int times) {
  for (int i = 0; i < times; i++) {
    digitalWrite(ledPin, HIGH);
    delay(500);
    digitalWrite(ledPin, LOW);
    delay(500);
  }
}

void reconnect() {
  // Loop until we're reconnected
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    
    // Attempt to connect without authentication
    if (client.connect(mqtt_client_id)) {
      Serial.println("connected");
      
      // Subscribe to the blink command topic
      client.subscribe(mqtt_subscribe_topic);
      Serial.print("Subscribed to: ");
      Serial.println(mqtt_subscribe_topic);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW); // Start with LED off
  
  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  unsigned long now = millis();
  if (now - lastMsgTime > msgInterval) {
    lastMsgTime = now;
    
    // Create JSON message
    StaticJsonDocument<200> jsonDoc;
    jsonDoc["aoaddress"] = ao_process_address;
    jsonDoc["data"] = "hello world";
    
    // Serialize JSON to string
    char jsonBuffer[200];
    serializeJson(jsonDoc, jsonBuffer);
    
    Serial.print("Publishing message: ");
    Serial.println(jsonBuffer);
    
    // Publish JSON message
    client.publish(mqtt_publish_topic, jsonBuffer);
  }
}