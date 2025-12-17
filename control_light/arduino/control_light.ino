/*
  Lumen Control - Arduino side
  - Three blocks, four LEDs each (on/off control)
    Block 1 -> pins 4,5,6,7
    Block 2 -> pins 8,9,10,11
    Block 3 -> pins 12,13,A0,A1
  - Link indicator LED on pin A2 blinks when connected
  Expects payloads:
    block-<1..3>-<0..3>-<0 or 1>
  plus heartbeat "ping" (responds "pong").
*/

#include <SoftwareSerial.h>

SoftwareSerial btSerial(2, 3); // RX, TX

const byte BLOCK_COUNT = 3;
const byte LIGHTS_PER_BLOCK = 4;
const byte blockPins[BLOCK_COUNT][LIGHTS_PER_BLOCK] = {
  {4, 5, 6, 7},
  {8, 9, 10, 11},
  {12, 13, A0, A1}
};

const byte LINK_LED_PIN = A2;
const unsigned long heartbeatTimeout = 10000; // ms
const unsigned long blinkInterval = 500;      // ms

String inputBuffer;
unsigned long lastDataTime = 0;
unsigned long lastBlinkTime = 0;
bool blinkState = false;

void setup() {
  for (byte b = 0; b < BLOCK_COUNT; b++) {
    for (byte i = 0; i < LIGHTS_PER_BLOCK; i++) {
      pinMode(blockPins[b][i], OUTPUT);
      digitalWrite(blockPins[b][i], LOW);
    }
  }
  pinMode(LINK_LED_PIN, OUTPUT);
  digitalWrite(LINK_LED_PIN, LOW);

  Serial.begin(9600);
  btSerial.begin(9600);
  lastDataTime = millis();
  Serial.println(F("Multi-block on/off controller ready (SoftSerial 2/3)"));
}

void loop() {
  while (btSerial.available()) {
    char c = btSerial.read();
    if (c == '\n' || c == '\r') {
      if (inputBuffer.length() > 0) {
        handleCommand(inputBuffer);
        inputBuffer = "";
      }
      lastDataTime = millis();
    } else {
      inputBuffer += c;
      if (inputBuffer.length() > 64) inputBuffer = "";
      lastDataTime = millis();
    }
  }

  updateLinkLed();
}

void updateLinkLed() {
  const bool linked = (millis() - lastDataTime) <= heartbeatTimeout;
  if (linked) {
    if (millis() - lastBlinkTime >= blinkInterval) {
      blinkState = !blinkState;
      digitalWrite(LINK_LED_PIN, blinkState ? HIGH : LOW);
      lastBlinkTime = millis();
    }
  } else {
    blinkState = false;
    digitalWrite(LINK_LED_PIN, LOW);
  }
}

void handleCommand(String cmd) {
  cmd.trim();
  if (cmd.length() == 0) return;

  if (cmd == "ping") {
    Serial.println(F("pong"));
    btSerial.println(F("pong"));
    return;
  }

  int firstDash = cmd.indexOf('-');
  int secondDash = cmd.indexOf('-', firstDash + 1);
  int thirdDash = cmd.indexOf('-', secondDash + 1);

  if (firstDash == -1 || secondDash == -1 || thirdDash == -1) {
    Serial.println(F("ERR format"));
    btSerial.println(F("ERR format"));
    return;
  }

  String blockPart = cmd.substring(firstDash + 1, secondDash);
  String ledPart = cmd.substring(secondDash + 1, thirdDash);
  String valuePart = cmd.substring(thirdDash + 1);

  int blockNum = blockPart.toInt(); // 1-based
  int ledIdx = ledPart.toInt();     // 0-based
  int stateVal = valuePart.toInt();

  if (blockNum < 1 || blockNum > BLOCK_COUNT ||
      ledIdx < 0 || ledIdx >= LIGHTS_PER_BLOCK) {
    Serial.println(F("ERR addr"));
    btSerial.println(F("ERR addr"));
    return;
  }

  if (stateVal != 0 && stateVal != 1) {
    Serial.println(F("ERR state"));
    btSerial.println(F("ERR state"));
    return;
  }

  const byte targetPin = blockPins[blockNum - 1][ledIdx];
  digitalWrite(targetPin, stateVal == 1 ? HIGH : LOW);

  Serial.print(F("OK "));
  Serial.print(blockNum);
  Serial.print('-');
  Serial.print(ledIdx);
  Serial.print(F("->"));
  Serial.println(stateVal);

  btSerial.print(F("OK "));
  btSerial.print(blockNum);
  btSerial.print('-');
  btSerial.print(ledIdx);
  btSerial.print(F("->"));
  btSerial.println(stateVal);
}
