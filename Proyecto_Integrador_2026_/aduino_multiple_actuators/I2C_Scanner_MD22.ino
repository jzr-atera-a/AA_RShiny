/*
 * Arduino Dual Servo + MD22 Motor Controller for Meta Quest 3 Integration
 * Receives commands via Serial from Jetson Nano
 * Controls:
 *   - Servo1 on Pin 8 (Range: 40-140 degrees)
 *   - Servo2 on Pin 9 (Range: 50-130 degrees)
 *   - MD22 Motor1 via I2C (Speed: 0-33% forward only)
 * 
 * Hardware:
 * - Arduino Nano/Uno/Mega
 * - Servo1 motor connected to Pin 8 (40-140° range)
 * - Servo2 motor connected to Pin 9 (50-130° range)
 * - MD22 H-bridge connected via I2C (SDA/SCL)
 * - USB connection to Jetson Nano
 * 
 * MD22 I2C Connection:
 * - Arduino SDA → MD22 SDA
 * - Arduino SCL → MD22 SCL
 * - Common GND between Arduino and MD22
 * 
 * Serial Commands:
 *   SERVO1:angle      - Set servo1 to angle (40-140 degrees)
 *   SERVO2:angle      - Set servo2 to angle (50-130 degrees)
 *   SERVO1_CENTER     - Center servo1 to 90 degrees
 *   SERVO2_CENTER     - Center servo2 to 90 degrees
 *   MOTOR1:speed      - Set motor1 speed (0-33 for 0-33% forward)
 *   MOTOR1_STOP       - Stop motor1 (speed = 0)
 *   PING              - Respond with PONG
 *   STATUS            - Report current angles, motor speed, and status
 */

#include <Servo.h>
#include <Wire.h>

// Pin definitions
const int SERVO1_PIN = 8;  // New servo (40-140° range)
const int SERVO2_PIN = 9;  // Original servo (50-130° range)
const int LED_PIN = 13;

// MD22 I2C Configuration
const byte MD22_ADDRESS = 0x62;  // Address with DIP switches 1 and 3 ON (was 0x58)
const byte MD22_MOTOR1 = 0x00;   // Motor 1 speed register
const byte MD22_MOTOR2 = 0x01;   // Motor 2 speed register
const byte MD22_MODE = 0x0F;     // Mode register
const byte MD22_ACCELERATION = 0x0E; // Acceleration register

// MD22 Speed constants (Mode 0: 0=full reverse, 128=stop, 255=full forward)
const byte MD22_STOP = 128;
const byte MD22_MAX_FORWARD = 255;
const byte MD22_MAX_REVERSE = 0;

// Motor speed limits (0-33% of full speed)
const int MOTOR_MIN_PERCENT = 0;
const int MOTOR_MAX_PERCENT = 33;

// Servo objects
Servo servo1;  // Pin 8 - New servo
Servo servo2;  // Pin 9 - Original servo

// Servo range limits
const int SERVO1_MIN = 40;
const int SERVO1_MAX = 140;
const int SERVO2_MIN = 50;
const int SERVO2_MAX = 130;

// State variables
int currentAngle1 = 90;         // Current servo1 position
int currentAngle2 = 90;         // Current servo2 position
int currentMotor1Speed = 0;     // Current motor1 speed (0-33%)
bool servo1Attached = false;
bool servo2Attached = false;
bool md22Available = false;
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
  
  // Initialize I2C for MD22
  Wire.begin();
  initMD22();
  
  // Attach servos and center them
  attachServo1();
  attachServo2();
  centerServo1();
  centerServo2();
  
  // Reserve string buffer
  inputString.reserve(200);
  
  // Send startup message
  Serial.println("Arduino Dual Servo + MD22 Motor Controller Ready");
  Serial.println("Commands: SERVO1:angle, SERVO2:angle, SERVO1_CENTER, SERVO2_CENTER");
  Serial.println("          MOTOR1:speed, MOTOR1_STOP, PING, STATUS");
  Serial.println("Servo1 (Pin 8): Range 40-140 degrees");
  Serial.println("Servo2 (Pin 9): Range 50-130 degrees");
  Serial.println("Motor1 (MD22 via I2C): Speed 0-33% forward only");
  Serial.print("MD22 Status: ");
  Serial.println(md22Available ? "Connected" : "Not detected");
  Serial.print("Current angles - Servo1: ");
  Serial.print(currentAngle1);
  Serial.print("° | Servo2: ");
  Serial.print(currentAngle2);
  Serial.print("° | Motor1: ");
  Serial.print(currentMotor1Speed);
  Serial.println("%");
  
  // Flash LED to indicate ready
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(100);
    digitalWrite(LED_PIN, LOW);
    delay(100);
  }
}

void loop() {
  // Read serial commands - MUST be called explicitly for Arduino Mega
  if (Serial.available() > 0) {
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
  
  // Process complete commands
  if (stringComplete) {
    processCommand(inputString);
    inputString = "";
    stringComplete = false;
  }
  
  // Blink LED when servos are active or motor running
  if (servo1Attached || servo2Attached || currentMotor1Speed > 0) {
    digitalWrite(LED_PIN, (millis() / 500) % 2);
  }
}

void initMD22() {
  /**
   * Initialize MD22 H-bridge controller
   * Set to Mode 0: 0=full reverse, 128=stop, 255=full forward
   * Set acceleration to moderate value
   */
  
  // Test I2C connection
  Wire.beginTransmission(MD22_ADDRESS);
  byte error = Wire.endTransmission();
  
  if (error == 0) {
    md22Available = true;
    
    // Set MD22 to Mode 0 (0-255 speed range)
    writeMD22Register(MD22_MODE, 0);
    delay(10);
    
    // Set moderate acceleration (5 = about 0.5 seconds to full speed)
    writeMD22Register(MD22_ACCELERATION, 5);
    delay(10);
    
    // Stop both motors
    writeMD22Register(MD22_MOTOR1, MD22_STOP);
    writeMD22Register(MD22_MOTOR2, MD22_STOP);
    delay(10);
    
    Serial.println("MD22 initialized successfully");
  } else {
    md22Available = false;
    Serial.println("WARNING: MD22 not found on I2C bus");
    Serial.println("Check SDA/SCL connections and MD22 power");
  }
}

void writeMD22Register(byte reg, byte value) {
  /**
   * Write a value to MD22 register via I2C
   */
  Wire.beginTransmission(MD22_ADDRESS);
  Wire.write(reg);
  Wire.write(value);
  Wire.endTransmission();
}

byte percentToMD22Speed(int percent) {
  /**
   * Convert percentage (0-33) to MD22 speed value (128-170)
   * 0% → 128 (stop)
   * 33% → 170 (33% of forward range)
   */
  
  // Clamp to valid range
  percent = constrain(percent, MOTOR_MIN_PERCENT, MOTOR_MAX_PERCENT);
  
  // Calculate MD22 speed value
  // Forward range is 128-255 (127 steps)
  // 33% of 127 = 42 steps
  // So: 128 + (percent * 42 / 33)
  int speedRange = (MD22_MAX_FORWARD - MD22_STOP);  // 127
  int allowedRange = (speedRange * MOTOR_MAX_PERCENT) / 100;  // 42
  byte md22Speed = MD22_STOP + ((percent * allowedRange) / MOTOR_MAX_PERCENT);
  
  return md22Speed;
}

void setMotor1Speed(int percent) {
  /**
   * Set Motor1 speed (0-33% forward only)
   */
  if (!md22Available) {
    Serial.println("ERROR: MD22 not available");
    return;
  }
  
  // Clamp to valid range
  percent = constrain(percent, MOTOR_MIN_PERCENT, MOTOR_MAX_PERCENT);
  
  // Convert to MD22 speed value
  byte md22Speed = percentToMD22Speed(percent);
  
  // Send to MD22
  writeMD22Register(MD22_MOTOR1, md22Speed);
  currentMotor1Speed = percent;
  
  Serial.print("Motor1 speed set to ");
  Serial.print(percent);
  Serial.print("% (MD22 value: ");
  Serial.print(md22Speed);
  Serial.println(")");
}

void stopMotor1() {
  /**
   * Stop Motor1
   */
  if (!md22Available) {
    return;
  }
  
  writeMD22Register(MD22_MOTOR1, MD22_STOP);
  currentMotor1Speed = 0;
  Serial.println("Motor1 stopped");
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
    Serial.print("° (Pin 9, Range 50-130°) Attached=");
    Serial.print(servo2Attached ? "YES" : "NO");
    Serial.print(" | Motor1=");
    Serial.print(currentMotor1Speed);
    Serial.print("% MD22=");
    Serial.println(md22Available ? "Connected" : "Disconnected");
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
  
  // MOTOR1_STOP command - stop motor1
  if (command == "MOTOR1_STOP") {
    stopMotor1();
    Serial.println("OK: Motor1 stopped");
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
    
    // Validate angle range for servo2 (50-130)
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
  
  // MOTOR1:speed command - set motor1 speed (0-33%)
  if (command.startsWith("MOTOR1:")) {
    String speedStr = command.substring(7);
    int speed = speedStr.toInt();
    
    // Validate speed range (0-33%)
    if (speed >= MOTOR_MIN_PERCENT && speed <= MOTOR_MAX_PERCENT) {
      setMotor1Speed(speed);
      Serial.print("OK: Motor1 set to ");
      Serial.print(speed);
      Serial.println("%");
    } else {
      Serial.print("ERROR: Motor1 speed ");
      Serial.print(speed);
      Serial.print(" out of range (");
      Serial.print(MOTOR_MIN_PERCENT);
      Serial.print("-");
      Serial.print(MOTOR_MAX_PERCENT);
      Serial.println("%)");
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
