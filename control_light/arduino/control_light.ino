/*
  Lumen Control - Arduino side
  - One controllable LED on pin 11 (change CONTROL_LED_PIN if needed)
  - Link indicator LED on pin 13 (onboard) to show recent traffic
  Works with HC-05/HC-06 UART modules. Expects payloads:
    block-1-0-1   (block id 1, light index 0, state 0/1)
  Heartbeats from the app ("ping") also keep the link LED on.
*/

const byte CONTROL_LED_PIN = 11;  // driven by app commands
const byte LINK_LED_PIN     = 13; // onboard LED for link status

String inputBuffer;
unsigned long lastDataTime = 0;
const unsigned long timeoutMs = 10000; // 10s without data => link off

void setup() {
  pinMode(CONTROL_LED_PIN, OUTPUT);
  pinMode(LINK_LED_PIN, OUTPUT);
  digitalWrite(CONTROL_LED_PIN, LOW);
  digitalWrite(LINK_LED_PIN, LOW);

  Serial.begin(9600); // HC-05 default baud
  while (!Serial) { ; }
  Serial.println(F("Single LED controller ready"));
}

void loop() {
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') {
      if (inputBuffer.length() > 0) {
        handleCommand(inputBuffer);
        inputBuffer = "";
      }
      lastDataTime = millis();
    } else {
      inputBuffer += c;
      if (inputBuffer.length() > 32) inputBuffer = "";
      lastDataTime = millis();
    }
  }

  // Update link LED based on recent traffic (heartbeat or commands)
  if (millis() - lastDataTime <= timeoutMs) {
    digitalWrite(LINK_LED_PIN, HIGH);
  } else {
    digitalWrite(LINK_LED_PIN, LOW);
  }
}

void handleCommand(String cmd) {
  cmd.trim(); // remove any stray whitespace/CR

  if (cmd == "ping") {
    Serial.println(F("pong"));
    return;
  }

  // Expected: block-1-0-1 or block-1-0-0
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

  if (blockPart != "1" || idxPart != "0") {
    Serial.println(F("ERR addr"));
    return;
  }

  statePart.trim();
  int stateVal = statePart.toInt(); // 0 or 1
  if (stateVal != 0 && stateVal != 1) {
    Serial.println(F("ERR state"));
    return;
  }

  digitalWrite(CONTROL_LED_PIN, stateVal == 1 ? HIGH : LOW);
  Serial.print(F("OK 1-0->"));
  Serial.println(stateVal);
}
