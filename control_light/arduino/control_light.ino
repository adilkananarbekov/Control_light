/*
  Lumen Control - Arduino side
  Works with HC-05/HC-06/HM-10 style UART modules. Expects payloads like:
    block-1-0-1   (block id, light index 0..3, state 0/1)
  Wiring below assumes:
    Block 1 LEDs -> pins 2,3,4,5
    Block 2 LEDs -> pins 6,7,8,9
    Block 3 LEDs -> pins 10,11,12,13
  Adjust the pin map if your wiring differs.
*/

const byte BLOCK_COUNT = 3;
const byte LIGHTS_PER_BLOCK = 4;

const byte blockPins[BLOCK_COUNT][LIGHTS_PER_BLOCK] = {
  {2, 3, 4, 5},       // block-1
  {6, 7, 8, 9},       // block-2
  {10, 11, 12, 13}    // block-3
};

// Simple input buffer for one line of text.
String inputBuffer;

void setup() {
  // Init LED pins.
  for (byte b = 0; b < BLOCK_COUNT; b++) {
    for (byte i = 0; i < LIGHTS_PER_BLOCK; i++) {
      pinMode(blockPins[b][i], OUTPUT);
      digitalWrite(blockPins[b][i], LOW);
    }
  }

  // Bluetooth serial (HC-05/HC-06 defaults to 9600).
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB only
  }
  Serial.println(F("Lumen Control ready"));
}

void loop() {
  // Read incoming characters until newline.
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') {
      if (inputBuffer.length() > 0) {
        handleCommand(inputBuffer);
        inputBuffer = "";
      }
    } else {
      inputBuffer += c;
      // Avoid runaway buffer.
      if (inputBuffer.length() > 64) {
        inputBuffer = "";
      }
    }
  }
}

void handleCommand(const String &cmd) {
  // Expected: block-X-Y-Z  (X=1..3, Y=0..3, Z=0/1)
  // Split by '-'
  int firstDash = cmd.indexOf('-');
  int secondDash = cmd.indexOf('-', firstDash + 1);
  int thirdDash = cmd.indexOf('-', secondDash + 1);

  if (firstDash == -1 || secondDash == -1 || thirdDash == -1) {
    Serial.println(F("ERR format"));
    return;
  }

  String blockPart = cmd.substring(firstDash + 1, secondDash);
  String idxPart = cmd.substring(secondDash + 1, thirdDash);
  String statePart = cmd.substring(thirdDash + 1);

  int blockNum = blockPart.toInt();   // 1-based
  int lightIdx = idxPart.toInt();     // 0-based
  int stateVal = statePart.toInt();   // 0 or 1

  if (blockNum < 1 || blockNum > BLOCK_COUNT ||
      lightIdx < 0 || lightIdx >= LIGHTS_PER_BLOCK ||
      (stateVal != 0 && stateVal != 1)) {
    Serial.println(F("ERR range"));
    return;
  }

  byte pin = blockPins[blockNum - 1][lightIdx];
  digitalWrite(pin, stateVal == 1 ? HIGH : LOW);
  Serial.print(F("OK "));
  Serial.print(blockNum);
  Serial.print(F("-"));
  Serial.print(lightIdx);
  Serial.print(F("->"));
  Serial.println(stateVal);
}
