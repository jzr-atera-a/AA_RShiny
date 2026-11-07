/*
 * Arduino Dual Servo + MD22 Motor Controller for Meta Quest 3 Integration
 * Receives commands via Serial from Jetson Nano
 * Controls:
 *   - Servo1 on Pin 8 (Range: 40-140 degrees) - Controlled by RIGHT A/B buttons
 *   - Servo2 on Pin 9 (Range: 50-130 degrees) - Controlled by RIGHT joystick X
 *   - MD22 Motor1 via I2C (Speed: 50-90% forward) - Controlled by LEFT joystick Y
 *   - MD22 Motor2 via I2C (Speed: 50-90% forward) - Controlled by LEFT joystick Y
 *
 * Hardware:
 * - Arduino Mega 2560 (recommended for I2C on pins 20/21)
 * - Servo1 motor connected to Pin 8 (40-140° range)
 * - Servo2 motor connected to Pin 9 (50-130° range)
 * - MD22 H-bridge connected via I2C (SDA pin 20, SCL pin 21)
 * - USB connection to Jetson Nano
 *
 * MD22 I2C Connection:
 * - Arduino Pin 20 (SDA) → MD22 SDA
 * - Arduino Pin 21 (SCL) → MD22 SCL
 * - Arduino GND → MD22 GND
 * - External 12V → MD22 motor power
 *
 * Serial Commands (115200 baud):
 *   SERVO1:angle      - Set servo1 to angle (40-140 degrees)
 *   SERVO2:angle      - Set servo2 to angle (50-130 degrees)
 *   SERVO1_CENTER     - Center servo1 to 90 degrees
 *   SERVO2_CENTER     - Center servo2 to 90 degrees
 *   MOTOR1:speed      - Set motor1 speed (50-90 for 50-90% forward)
 *   MOTOR2:speed      - Set motor2 speed (50-90 for 50-90% forward)
 *   MOTORS:speed      - Set both motors to same speed (50-90%)
 *   M1_STOP           - Stop motor1
 *   M2_STOP           - Stop motor2
 *   STOP_ALL_MOTORS   - Stop both motors
 *   PING              - Respond with PONG
 *   STATUS            - Report current angles, motor speeds, and status
 */

#include <Servo.h>
#include <Wire.h>

// Pin definitions
const int SERVO1_PIN = 8;  // RIGHT A/B buttons - servo control
const int SERVO2_PIN = 9;  // RIGHT joystick X - steering control
const int LED_PIN = 13;

// MD22 I2C Configuration
const byte MD22_ADDRESS = 0x58;      // Default MD22 I2C address
const byte MD22_MODE_REG = 0x00;     // Mode register
const byte MD22_MOTOR1_REG = 0x01;   // Motor 1 speed register
const byte MD22_MOTOR2_REG = 0x02;   // Motor 2 speed register
const byte MD22_ACCELERATION_REG = 0x03;  // Acceleration register
const byte MD22_VERSION_REG = 0x07;  // Version register

// MD22 Speed constants (Mode 0: 0=full reverse, 128=stop, 255=full forward)
const byte MD22_STOP = 128;
const byte MD22_MAX_FORWARD = 255;
const byte MD22_MAX_REVERSE = 0;

// Motor speed limits (50-90% of full speed for 4-wheel robot)
const int MOTOR_MIN_PERCENT = 50;  // Motors don't move below 50%
const int MOTOR_MAX_PERCENT = 90;  // 100% would pull too much current

// Servo objects
Servo servo1;  // Pin 8 - RIGHT A/B button control
Servo servo2;  // Pin 9 - RIGHT joystick X control (steering)

// Servo range limits
const int SERVO1_MIN = 40;
const int SERVO1_MAX = 140;
const int SERVO2_MIN = 50;
const int SERVO2_MAX = 130;

// State variables
int currentServo1Angle = 90;        // Current servo1 position
int currentServo2Angle = 90;        // Current servo2 position
int currentMotor1Speed = 0;         // Current motor1 speed (50-90%)
int currentMotor2Speed = 0;         // Current motor2 speed (50-90%)
bool servo1Attached = false;
bool servo2Attached = false;
bool md22Available = false;
byte md22SoftwareVersion = 0;
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
  delay(100);
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
  Serial.println("Commands: SERVO1:angle, SERVO2:angle, MOTORS:speed, M1_STOP, M2_STOP");
  Serial.println("Servo1 (Pin 8): Range 40-140 degrees (RIGHT A/B buttons)");
  Serial.println("Servo2 (Pin 9): Range 50-130 degrees (RIGHT joystick X - steering)");
  Serial.println("Motors (MD22 via I2C): Speed 50-90% forward (LEFT joystick Y)");
  Serial.print("MD22 Status: ");
  Serial.println(md22Available ? "Connected" : "Not detected");
  Serial.print("Current state - Servo1: ");
  Serial.print(currentServo1Angle);
  Serial.print("° | Servo2: ");
  Serial.print(currentServo2Angle);
  Serial.print("° | Motor1: ");
  Serial.print(currentMotor1Speed);
  Serial.print("% | Motor2: ");
  Serial.print(currentMotor2Speed);
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
  // Read serial commands
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
 
  // Blink LED when servos are active or motors running
  if (servo1Attached || servo2Attached || currentMotor1Speed > 0 || currentMotor2Speed > 0) {
    digitalWrite(LED_PIN, (millis() / 500) % 2);
  }
}

// ============================================
// MD22 MOTOR CONTROL FUNCTIONS
// ============================================

void initMD22() {
  /**
   * Initialize MD22 H-bridge controller
   * Set to Mode 0: 0=full reverse, 128=stop, 255=full forward
   * Set acceleration to moderate value
   */
  Serial.println("Initializing MD22...");
  
  // Test I2C connection
  Wire.beginTransmission(MD22_ADDRESS);
  byte error = Wire.endTransmission();
 
  if (error == 0) {
    md22Available = true;
    Serial.println("  MD22 found at 0x58");
   
    // Read software version
    md22SoftwareVersion = readMD22Register(MD22_VERSION_REG);
    Serial.print("  Software version: ");
    Serial.println(md22SoftwareVersion);
   
    // Set MD22 to Mode 0 (0-255 speed range)
    writeMD22Register(MD22_MODE_REG, 0);
    delay(50);
    byte modeCheck = readMD22Register(MD22_MODE_REG);
    Serial.print("  Mode set to: ");
    Serial.println(modeCheck);
   
    // Set moderate acceleration (10 = about 1 second to full speed)
    writeMD22Register(MD22_ACCELERATION_REG, 10);
    delay(50);
    Serial.println("  Acceleration set to 10");
   
    // Stop both motors
    writeMD22Register(MD22_MOTOR1_REG, MD22_STOP);
    writeMD22Register(MD22_MOTOR2_REG, MD22_STOP);
    delay(50);
    Serial.println("  Both motors stopped");
   
    Serial.println("MD22 initialized successfully!");
  } else {
    md22Available = false;
    Serial.println("WARNING: MD22 not found on I2C bus");
    Serial.println("Check SDA/SCL connections and MD22 power");
    Serial.print("I2C error code: ");
    Serial.println(error);
  }
  Serial.println();
}

void writeMD22Register(byte reg, byte value) {
  /**
   * Write a value to MD22 register via I2C
   */
  Wire.beginTransmission(MD22_ADDRESS);
  Wire.write(reg);
  Wire.write(value);
  Wire.endTransmission();
  delay(5);
}

byte readMD22Register(byte reg) {
  /**
   * Read a value from MD22 register via I2C
   */
  Wire.beginTransmission(MD22_ADDRESS);
  Wire.write(reg);
  Wire.endTransmission();
  
  delay(5);
  Wire.requestFrom(MD22_ADDRESS, (byte)1);
  
  if (Wire.available()) {
    return Wire.read();
  }
  return 0;
}

byte percentToMD22Speed(int percent) {
  /**
   * Convert percentage (50-90) to MD22 speed value
   * 0% → 128 (stop)
   * 50% → 192 (halfway forward)
   * 90% → 242 (90% forward)
   * 100% → 255 (full forward)
   */
 
  // Clamp to valid range
  if (percent <= 0) {
    return MD22_STOP;
  }
  
  percent = constrain(percent, 0, 100);
 
  // Calculate MD22 speed value
  // Forward range is 128-255 (127 steps)
  // Scale percentage to this range
  int speedRange = (MD22_MAX_FORWARD - MD22_STOP);  // 127
  byte md22Speed = MD22_STOP + ((percent * speedRange) / 100);
 
  return md22Speed;
}

void setMotor1Speed(int percent) {
  /**
   * Set Motor1 speed (0=stop, 50-90% forward)
   */
  if (!md22Available) {
    Serial.println("ERROR: MD22 not available");
    return;
  }
 
  // Clamp to valid range
  percent = constrain(percent, 0, MOTOR_MAX_PERCENT);
 
  // Convert to MD22 speed value
  byte md22Speed = percentToMD22Speed(percent);
 
  // Send to MD22
  writeMD22Register(MD22_MOTOR1_REG, md22Speed);
  delay(10);
  
  // Read back to verify
  byte readBack = readMD22Register(MD22_MOTOR1_REG);
  currentMotor1Speed = percent;
 
  Serial.print("Motor1: ");
  Serial.print(percent);
  Serial.print("% (MD22 value: ");
  Serial.print(md22Speed);
  Serial.print(", read back: ");
  Serial.print(readBack);
  Serial.println(")");
}

void setMotor2Speed(int percent) {
  /**
   * Set Motor2 speed (0=stop, 50-90% forward)
   */
  if (!md22Available) {
    Serial.println("ERROR: MD22 not available");
    return;
  }
 
  // Clamp to valid range
  percent = constrain(percent, 0, MOTOR_MAX_PERCENT);
 
  // Convert to MD22 speed value
  byte md22Speed = percentToMD22Speed(percent);
 
  // Send to MD22
  writeMD22Register(MD22_MOTOR2_REG, md22Speed);
  delay(10);
  
  // Read back to verify
  byte readBack = readMD22Register(MD22_MOTOR2_REG);
  currentMotor2Speed = percent;
 
  Serial.print("Motor2: ");
  Serial.print(percent);
  Serial.print("% (MD22 value: ");
  Serial.print(md22Speed);
  Serial.print(", read back: ");
  Serial.print(readBack);
  Serial.println(")");
}

void setBothMotorsSpeed(int percent) {
  /**
   * Set both motors to the same speed
   * Used for forward motion controlled by LEFT joystick Y
   */
  if (!md22Available) {
    Serial.println("ERROR: MD22 not available");
    return;
  }
  
  // Clamp to valid range
  percent = constrain(percent, 0, MOTOR_MAX_PERCENT);
  
  // Convert to MD22 speed value
  byte md22Speed = percentToMD22Speed(percent);
  
  // Send to both motors
  writeMD22Register(MD22_MOTOR1_REG, md22Speed);
  delay(5);
  writeMD22Register(MD22_MOTOR2_REG, md22Speed);
  delay(10);
  
  // Read back to verify
  byte readBack1 = readMD22Register(MD22_MOTOR1_REG);
  byte readBack2 = readMD22Register(MD22_MOTOR2_REG);
  
  currentMotor1Speed = percent;
  currentMotor2Speed = percent;
  
  Serial.print("Both Motors: ");
  Serial.print(percent);
  Serial.print("% (MD22 value: ");
  Serial.print(md22Speed);
  Serial.print(", M1: ");
  Serial.print(readBack1);
  Serial.print(", M2: ");
  Serial.print(readBack2);
  Serial.println(")");
}

void stopMotor1() {
  /**
   * Stop Motor1
   */
  if (!md22Available) {
    return;
  }
 
  writeMD22Register(MD22_MOTOR1_REG, MD22_STOP);
  currentMotor1Speed = 0;
  Serial.println("Motor1 stopped");
}

void stopMotor2() {
  /**
   * Stop Motor2
   */
  if (!md22Available) {
    return;
  }
 
  writeMD22Register(MD22_MOTOR2_REG, MD22_STOP);
  currentMotor2Speed = 0;
  Serial.println("Motor2 stopped");
}

void stopAllMotors() {
  /**
   * Stop both motors
   */
  if (!md22Available) {
    return;
  }
  
  writeMD22Register(MD22_MOTOR1_REG, MD22_STOP);
  delay(5);
  writeMD22Register(MD22_MOTOR2_REG, MD22_STOP);
  delay(10);
  
  currentMotor1Speed = 0;
  currentMotor2Speed = 0;
  Serial.println("All motors stopped");
}

// ============================================
// SERVO CONTROL FUNCTIONS
// ============================================

void setServo1Angle(int angle) {
  // Ensure servo is attached
  if (!servo1Attached) {
    attachServo1();
  }
 
  // Clamp angle to valid range for servo1
  angle = constrain(angle, SERVO1_MIN, SERVO1_MAX);
 
  // Move servo
  servo1.write(angle);
  currentServo1Angle = angle;
 
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
  currentServo2Angle = angle;
 
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
    servo1.write(currentServo1Angle);
    servo1Attached = true;
    digitalWrite(LED_PIN, HIGH);
  }
}

void attachServo2() {
  if (!servo2Attached) {
    servo2.attach(SERVO2_PIN);
    servo2.write(currentServo2Angle);
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

// ============================================
// COMMAND PROCESSING
// ============================================

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
    Serial.print(currentServo1Angle);
    Serial.print("° (Pin 8, Range 40-140°) Attached=");
    Serial.print(servo1Attached ? "YES" : "NO");
    Serial.print(" | Servo2=");
    Serial.print(currentServo2Angle);
    Serial.print("° (Pin 9, Range 50-130°) Attached=");
    Serial.print(servo2Attached ? "YES" : "NO");
    Serial.print(" | Motor1=");
    Serial.print(currentMotor1Speed);
    Serial.print("% | Motor2=");
    Serial.print(currentMotor2Speed);
    Serial.print("% | MD22=");
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
 
  // Motor stop commands
  if (command == "M1_STOP" || command == "MOTOR1_STOP") {
    stopMotor1();
    Serial.println("OK: Motor1 stopped");
    return;
  }
  
  if (command == "M2_STOP" || command == "MOTOR2_STOP") {
    stopMotor2();
    Serial.println("OK: Motor2 stopped");
    return;
  }
  
  if (command == "STOP_ALL_MOTORS" || command == "STOP_ALL") {
    stopAllMotors();
    Serial.println("OK: All motors stopped");
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
 
  // MOTOR1:speed command - set motor1 speed (0 or 50-90%)
  if (command.startsWith("MOTOR1:") || command.startsWith("M1:")) {
    int colonPos = command.indexOf(':');
    String speedStr = command.substring(colonPos + 1);
    int speed = speedStr.toInt();
   
    // Allow 0 (stop) or 50-90 range
    if (speed == 0 || (speed >= MOTOR_MIN_PERCENT && speed <= MOTOR_MAX_PERCENT)) {
      setMotor1Speed(speed);
      Serial.print("OK: Motor1 set to ");
      Serial.print(speed);
      Serial.println("%");
    } else {
      Serial.print("ERROR: Motor1 speed ");
      Serial.print(speed);
      Serial.print(" out of range (0 or ");
      Serial.print(MOTOR_MIN_PERCENT);
      Serial.print("-");
      Serial.print(MOTOR_MAX_PERCENT);
      Serial.println("%)");
    }
    return;
  }
  
  // MOTOR2:speed command - set motor2 speed (0 or 50-90%)
  if (command.startsWith("MOTOR2:") || command.startsWith("M2:")) {
    int colonPos = command.indexOf(':');
    String speedStr = command.substring(colonPos + 1);
    int speed = speedStr.toInt();
   
    // Allow 0 (stop) or 50-90 range
    if (speed == 0 || (speed >= MOTOR_MIN_PERCENT && speed <= MOTOR_MAX_PERCENT)) {
      setMotor2Speed(speed);
      Serial.print("OK: Motor2 set to ");
      Serial.print(speed);
      Serial.println("%");
    } else {
      Serial.print("ERROR: Motor2 speed ");
      Serial.print(speed);
      Serial.print(" out of range (0 or ");
      Serial.print(MOTOR_MIN_PERCENT);
      Serial.print("-");
      Serial.print(MOTOR_MAX_PERCENT);
      Serial.println("%)");
    }
    return;
  }
  
  // MOTORS:speed command - set both motors to same speed (0 or 50-90%)
  if (command.startsWith("MOTORS:")) {
    String speedStr = command.substring(7);
    int speed = speedStr.toInt();
   
    // Allow 0 (stop) or 50-90 range
    if (speed == 0 || (speed >= MOTOR_MIN_PERCENT && speed <= MOTOR_MAX_PERCENT)) {
      setBothMotorsSpeed(speed);
      Serial.print("OK: Both motors set to ");
      Serial.print(speed);
      Serial.println("%");
    } else {
      Serial.print("ERROR: Motor speed ");
      Serial.print(speed);
      Serial.print(" out of range (0 or ");
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
