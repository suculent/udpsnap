// Wemos D1 with L293N-based motor driver, HS17 motor and 

#include "ESP8266WiFi.h"
#include "WiFiUdp.h"
#include <ESP8266mDNS.h>

// The port can be any integer between 1024 and 65535
const unsigned int NET_PORT = 58266;

WiFiUDP Udp;

const int LED_PIN = D4;

char net_payload[6] = "P:999";

IPAddress clientIP = atoi("192.168.1.18");
int clientPort;

void udp_broadcast(int index){  

  sprintf(net_payload, "P:%i", index);
  
  /*
   /IPAddress broadcastIP = ~WiFi.subnetMask() | WiFi.gatewayIP();
  
  Udp.beginPacket(broadcastIP, NET_PORT);
  Udp.write(net_payload);
  Udp.endPacket();
  * 
   */

  Serial.println("clientIP");
  Serial.println(clientIP);
  Serial.println("clientPort");
  Serial.println(clientPort);
    
  Udp.beginPacket(clientIP, clientPort);
  Udp.write(net_payload);
  Udp.endPacket();  
}

#include <Stepper.h>

const int stepsPerRevolution = 200;  // 1.8° per step
Stepper myStepper(stepsPerRevolution, D5, D6, D7, D8);

// Max RPM is 40!
unsigned long timeout;
bool ledstate = false;

void setup() {
  Serial.begin(230400);
  Serial.print("PINS: D5, D6, D7, D8");
  myStepper.setSpeed(10); // max seems 100 (percent?)

  WiFi.begin("THiNX-IoT", "<enter-your-ssid-password>");  
  delay(2000);

  int wifi_status;

  if (wifi_status != WL_CONNECTED) {    
    Serial.println(F("Waiting for WiFi connection..."));    
    timeout = millis() + 5000;
    while (millis() < timeout) {
      ledstate = !ledstate;
      digitalWrite(LED_PIN, ledstate);
      delay(500);
      Serial.print(".");
    }
  }

  digitalWrite(LED_PIN, LOW);


  MDNS.begin("rotopad");
  MDNS.addService("rotopad", "udp", NET_PORT); // for future commands: start, stop, rewind.

  Serial.println();
  Serial.println("Performing mDNS query...");
  int n = MDNS.queryService("camera", "udp");
  Serial.println("mDNS query done");
  if (n == 0) {
    Serial.println("No services found.");
  }
  else {
    Serial.print(n);
    Serial.println(" service(s) found");
    for (int i = 0; i < n; ++i) {
      // Print details for each service found
      Serial.print(i + 1);
      Serial.print(": ");
      Serial.print(MDNS.hostname(i));
      Serial.print(" (");
      Serial.print(MDNS.IP(i));
      Serial.print(":");
      Serial.print(MDNS.port(i));
      Serial.println(")");

      clientIP = MDNS.IP(i);
      clientPort = MDNS.port(i);
      break;
    }
  }
  Serial.println();

  Serial.println("Starting UDP server...");
  Udp.begin(NET_PORT);
}

int stepcount = 0;
unsigned long start = millis();

char packetBuffer[UDP_TX_PACKET_MAX_SIZE];
char replyBuffer[UDP_TX_PACKET_MAX_SIZE];

unsigned long interval = 2000;
unsigned long jitter = 100; // prevent vibrations

void loop() {

  if (stepcount < 200) {
    if (timeout < millis()) {
      stepcount++;
      unsigned long jitter_value = random(-jitter, jitter);
      timeout = millis() + interval + jitter_value;  // +10 = 20s/revolution
      digitalWrite(LED_PIN, HIGH);
      myStepper.step(-10);
      digitalWrite(LED_PIN, LOW);
      Serial.printf("step #%i (%u seconds)\n", stepcount, (millis() - start)/1000);
      // Broadcast step count to synchronize camera capture over UDP
      udp_broadcast(stepcount);
    }
  }

  int packetSize = Udp.parsePacket();
  if (packetSize)
  {
    Serial.print("Received packet of size ");
    Serial.println(packetSize);
    Serial.print("From ");
    IPAddress remote = Udp.remoteIP();
    for (int i = 0; i < 4; i++)
    {
      Serial.print(remote[i], DEC);
      if (i < 3)
      {
        Serial.print(".");
      }
    }
    Serial.print(", port ");
    Serial.println(Udp.remotePort());    

    // read the packet into packetBufffer
    Udp.read(packetBuffer, UDP_TX_PACKET_MAX_SIZE);
    Serial.println("Contents:");
    Serial.println(packetBuffer);

    // TODO: Support commands: PLAY, STOP, REWIND, INTERVAL, JITTER

    // Play will allow stepping, stop will disallow stepping.
    // Rewind will reset the stepcount to 0 while stepping 10*stepcount
    // Interval/Jitter will adjust respective parameter.
  }  
}

