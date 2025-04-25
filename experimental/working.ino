#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// WiFi credentials
const char* ssid = "abc";  // Your WiFi SSID
const char* password = "tcstcstp";  // Your WiFi password

// MQTT Broker settings
const char* mqtt_server = "57.128.58.120";  // Your MQTT broker IP
const int mqtt_port = 1883;
const char* mqtt_publish_topic = "root/main";
const char* mqtt_subscribe_topic = "iot/response/esp8266";  // Topic to receive responses
const char* mqtt_client_id = "ESP8266_IoT_Client";

// AO process addresses to send messages to (comma-separated)
const char* ao_processes = "jDIsVeRE7-rW5fBvCMYB05e4mnQWXWw-lvtTAb-EG9w";  // Replace with your target process IDs

// LED pin for visual feedback
const int ledPin = 2;  // GPIO2 is often the built-in LED on ESP8266

// Initialize WiFi and MQTT client
WiFiClient espClient;
PubSubClient client(espClient);

// Variables for message timing
unsigned long lastMsgTime = 0;
const long msgInterval = 10000;  // Send message every 10 seconds

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

// Callback for incoming MQTT messages
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  
  // Print message
  char message[length + 1];
  for (int i = 0; i < length; i++) {
    message[i] = (char)payload[i];
    Serial.print((char)payload[i]);
  }
  Serial.println();
  message[length] = '\0';
  
  // Blink LED to show we received a response
  digitalWrite(ledPin, HIGH);
  delay(500);
  digitalWrite(ledPin, LOW);
  
  // Parse JSON response if needed
  // For now, we just print it to serial
}

void reconnect() {
  // Loop until we're reconnected
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    
    // Attempt to connect
    if (client.connect(mqtt_client_id)) {
      Serial.println("connected");
      
      // Subscribe to the response topic
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
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW);
  
  Serial.begin(115200);
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
    
    // Flash LED to indicate sending
    digitalWrite(ledPin, HIGH);
    delay(100);
    digitalWrite(ledPin, LOW);
    
    // Create JSON message
    StaticJsonDocument<200> jsonDoc;
    jsonDoc["ao-processes"] = ao_processes;
    jsonDoc["data"] = "Hello from ESP8266 at " + String(now);
    jsonDoc["where-to-find-me"] = mqtt_subscribe_topic;
    
    // Serialize JSON to string
    char jsonBuffer[200];
    serializeJson(jsonDoc, jsonBuffer);
    
    Serial.print("Publishing message: ");
    Serial.println(jsonBuffer);
    
    // Publish JSON message
    client.publish(mqtt_publish_topic, jsonBuffer);
  }
}