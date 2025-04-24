#include <ESP8266WiFi.h>
#include <PubSubClient.h>

// Wi-Fi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// MQTT Broker IP (your Ubuntu server)
const char* mqtt_server = "YOUR_SERVER_IP";

WiFiClient espClient;
PubSubClient client(espClient);

const int ledPin = 2; // Built-in LED on most ESP8266 boards

void setup_wifi() {
  delay(10);
  Serial.begin(115200);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.print("Message received on ");
  Serial.print(topic);
  Serial.print(": ");
  Serial.println(message);

  if (message == "blink") {
    for (int i = 0; i < 3; i++) {
      digitalWrite(ledPin, LOW);
      delay(300);
      digitalWrite(ledPin, HIGH);
      delay(300);
    }
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect("ESP8266Client")) {
      Serial.println("connected");
      client.subscribe("esp/response");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" retrying in 5s...");
      delay(5000);
    }
  }
}

void setup() {
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, HIGH); // LED off
  setup_wifi();
  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  static unsigned long lastSend = 0;
  if (millis() - lastSend > 2000) {
    // Send to AO every 2 seconds
    String payload = "{\"ao-process-ad\":\"kACJrbbtyzdG0HSz4dVULKzQ1KUO2c_zU8KgUk6znFo\",\"payload\":\"Ping\"}";
    client.publish("master/iot", payload.c_str());
    Serial.println("Sent: " + payload);
    lastSend = millis();
  }
}
