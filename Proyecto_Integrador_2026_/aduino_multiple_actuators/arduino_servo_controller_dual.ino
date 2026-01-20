/*
 * Arduino Dual Servo Controller for Meta Quest 3 Integration
 * Receives commands via Serial from Jetson Nano
 * Controls two servos:
 *   - Servo1 on Pin 8 (Range: 40-140 degrees)
 *   - Servo2 on Pin 9 (Range: 0-180 degrees - original servo)
 * 
 * Hardware:
 * - Arduino Nano/Uno/Mega
 * - Servo1 motor connected to Pin 8 (40-140° range)
 * - Servo2 motor connected to Pin 9 (0-180° range)
 * - USB connection to Jetson Nano
 * 
 * Serial Commands:
 *   SERVO1:angle      - Set servo1 to angle (40-140 degrees)
 *   SERVO2:angle      - Set servo2 to angle (0-180 degrees)
 *   SERVO1_CENTER     - Center servo1 to 90 degrees
 *   SERVO2_CENTER     - Center servo2 to 90 degrees
 *   PING              - Respond with PONG
 *   STATUS            - Report current angles and status of both servos
 */

#include <Servo.h>

// Pin definitions
const int SERVO1_PIN = 8;  // New servo (40-140° range)
const int SERVO2_PIN = 9;  // Original servo (0-180° range)
const int LED_PIN = 13;

// Servo objects
Servo servo1;  // Pin 8 - New servo
Servo servo2;  // Pin 9 - Original servo

// Servo range limits
const int SERVO1_MIN = 40;
const int SERVO1_MAX = 140;
const int SERVO2_MIN = 0;
const int SERVO2_MAX = 180;

// State variables
int currentAngle1 = 90;         // Current servo1 position
int currentAngle2 = 90;         // Current servo2 position
bool servo1Attached = false;
bool servo2Attached = false;
unsigned long lastCommandTime = 0;
const unsigned long TIMEOUT_MS = 5000;  // 5 second timeout

// Command buffer
String inputString = "";
boolean stringComplete = false;

void setup() {
  // Initialize serial communication at 115200 baud
  Serial.begin(115200);
  while (!Serial) {
    ; // Wait for serial port to connect (needed for native USB)
  }
  
  // Initialize LED
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  // Attach servos and center them
  attachServo1();
  attachServo2();
  centerServo1();
  centerServo2();
  
  // Reserve string buffer
  inputString.reserve(200);
  
  // Send startup message
  Serial.println("Arduino Dual Servo Controller Ready");
  Serial.println("Commands: SERVO1:angle, SERVO2:angle, SERVO1_CENTER, SERVO2_CENTER, PING, STATUS");
  Serial.println("Servo1 (Pin 8): Range 40-140 degrees");
  Serial.println("Servo2 (Pin 9): Range 0-180 degrees");
  Serial.print("Current angles - Servo1: ");
  Serial.print(currentAngle1);
  Serial.print("° | Servo2: ");
  Serial.print(currentAngle2);
  Serial.println("°");
  
  // Flash LED to indicate ready
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(100);
    digitalWrite(LED_PIN, LOW);
    delay(100);
  }
}

void loop() {
  // Read serial commands
  serialEvent();
  
  // Process complete commands
  if (stringComplete) {
    processCommand(inputString);
    inputString = "";
    stringComplete = false;
  }
  
  // Blink LED when servos are active
  if (servo1Attached || servo2Attached) {
    digitalWrite(LED_PIN, (millis() / 500) % 2);
  }
}

void serialEvent() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    
    if (inChar == '\n' || inChar == '\r') {
      if (inputString.length() > 0) {
        stringComplete = true;
      }
    } else {
      inputString += inChar;
    }
  }
}

void processCommand(String command) {
  command.trim();
  command.toUpperCase();
  
  lastCommandTime = millis();
  
  // PING command - connectivity test
  if (command == "PING") {
    Serial.println("PONG");
    return;
  }
  
  // STATUS command - report current state
  if (command == "STATUS") {
    Serial.print("STATUS: Servo1=");
    Serial.print(currentAngle1);
    Serial.print("° (Pin 8, Range 40-140°) Attached=");
    Serial.print(servo1Attached ? "YES" : "NO");
    Serial.print(" | Servo2=");
    Serial.print(currentAngle2);
    Serial.print("° (Pin 9, Range 0-180°) Attached=");
    Serial.println(servo2Attached ? "YES" : "NO");
    return;
  }
  
  // SERVO1_CENTER command - move servo1 to 90 degrees
  if (command == "SERVO1_CENTER") {
    centerServo1();
    Serial.println("OK: Servo1 centered to 90 degrees");
    return;
  }
  
  // SERVO2_CENTER command - move servo2 to 90 degrees
  if (command == "SERVO2_CENTER") {
    centerServo2();
    Serial.println("OK: Servo2 centered to 90 degrees");
    return;
  }
  
  // SERVO1:angle command - set servo1 to specific angle
  if (command.startsWith("SERVO1:")) {
    String angleStr = command.substring(7);
    int angle = angleStr.toInt();
    
    // Validate angle range for servo1 (40-140)
    if (angle >= SERVO1_MIN && angle <= SERVO1_MAX) {
      setServo1Angle(angle);
      Serial.print("OK: Servo1 set to ");
      Serial.print(angle);
      Serial.println(" degrees");
    } else {
      Serial.print("ERROR: Servo1 angle ");
      Serial.print(angle);
      Serial.print(" out of range (");
      Serial.print(SERVO1_MIN);
      Serial.print("-");
      Serial.print(SERVO1_MAX);
      Serial.println(")");
    }
    return;
  }
  
  // SERVO2:angle command - set servo2 to specific angle
  if (command.startsWith("SERVO2:")) {
    String angleStr = command.substring(7);
    int angle = angleStr.toInt();
    
    // Validate angle range for servo2 (0-180)
    if (angle >= SERVO2_MIN && angle <= SERVO2_MAX) {
      setServo2Angle(angle);
      Serial.print("OK: Servo2 set to ");
      Serial.print(angle);
      Serial.println(" degrees");
    } else {
      Serial.print("ERROR: Servo2 angle ");
      Serial.print(angle);
      Serial.print(" out of range (");
      Serial.print(SERVO2_MIN);
      Serial.print("-");
      Serial.print(SERVO2_MAX);
      Serial.println(")");
    }
    return;
  }
  
  // Unknown command
  Serial.print("ERROR: Unknown command: ");
  Serial.println(command);
}

void setServo1Angle(int angle) {
  // Ensure servo is attached
  if (!servo1Attached) {
    attachServo1();
  }
  
  // Clamp angle to valid range for servo1
  angle = constrain(angle, SERVO1_MIN, SERVO1_MAX);
  
  // Move servo
  servo1.write(angle);
  currentAngle1 = angle;
  
  // Small delay for servo to start moving
  delay(15);
}

void setServo2Angle(int angle) {
  // Ensure servo is attached
  if (!servo2Attached) {
    attachServo2();
  }
  
  // Clamp angle to valid range for servo2
  angle = constrain(angle, SERVO2_MIN, SERVO2_MAX);
  
  // Move servo
  servo2.write(angle);
  currentAngle2 = angle;
  
  // Small delay for servo to start moving
  delay(15);
}

void centerServo1() {
  setServo1Angle(90);
}

void centerServo2() {
  setServo2Angle(90);
}

void attachServo1() {
  if (!servo1Attached) {
    servo1.attach(SERVO1_PIN);
    servo1.write(currentAngle1);
    servo1Attached = true;
    digitalWrite(LED_PIN, HIGH);
  }
}

void attachServo2() {
  if (!servo2Attached) {
    servo2.attach(SERVO2_PIN);
    servo2.write(currentAngle2);
    servo2Attached = true;
    digitalWrite(LED_PIN, HIGH);
  }
}

void detachServo1() {
  if (servo1Attached) {
    servo1.detach();
    servo1Attached = false;
  }
}

void detachServo2() {
  if (servo2Attached) {
    servo2.detach();
    servo2Attached = false;
  }
}
