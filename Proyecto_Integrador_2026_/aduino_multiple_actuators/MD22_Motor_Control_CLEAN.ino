/*
 * MD22 DUAL MOTOR CONTROLLER
 * 
 * CONFIGURATION:
 * - DIP Switches: 1,2,3,4 ALL ON
 * - I2C Address: 0x58
 * 
 * Hardware Connections:
 * - Arduino Mega Pin 20 (SDA) to MD22 SDA
 * - Arduino Mega Pin 21 (SCL) to MD22 SCL
 * - Arduino 5V to MD22 5V
 * - Arduino GND to MD22 GND
 * - External 12V to MD22 12V motor power
 * - Motor 1 to MD22 M1A, M1B
 * - Motor 2 to MD22 M2A, M2B
 * 
 * Serial Commands (115200 baud):
 *   M1:50        - Set Motor1 to 50 percent
 *   M2:75        - Set Motor2 to 75 percent
 *   M1_STOP      - Stop Motor1
 *   M2_STOP      - Stop Motor2
 *   STOP_ALL     - Stop both motors
 *   TEST_M1      - Test Motor1
 *   TEST_M2      - Test Motor2
 *   TEST_BOTH    - Test both motors
 *   DIAG         - Full diagnostics
 *   STATUS       - Current status
 *   PING         - Test connection
 */

#include <Wire.h>

const byte MD22_ADDRESS = 0x58;
const byte MD22_MODE_REG = 0x00;
const byte MD22_MOTOR1_REG = 0x01;
const byte MD22_MOTOR2_REG = 0x02;
const byte MD22_ACCELERATION_REG = 0x03;
const byte MD22_VERSION_REG = 0x07;

const byte MD22_STOP = 128;
const byte MD22_FULL_FORWARD = 255;
const byte MD22_FULL_REVERSE = 0;

const int MOTOR_MIN_PERCENT = 0;
const int MOTOR_MAX_PERCENT = 100;

int currentMotor1Percent = 0;
int currentMotor2Percent = 0;
byte currentMotor1Value = MD22_STOP;
byte currentMotor2Value = MD22_STOP;

bool md22Available = false;
byte md22SoftwareVersion = 0;

String inputString = "";
boolean stringComplete = false;

const int LED_PIN = 13;

void setup() {
  Serial.begin(115200);
  while (!Serial);
  
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  delay(1000);
  
  printHeader();
  
  Wire.begin();
  delay(100);
  
  initMD22();
  
  if (md22Available) {
    printCommands();
  } else {
    Serial.println("ERROR: MD22 initialization failed!");
    Serial.println("Check connections and power.");
  }
  
  Serial.println("=========================================");
  Serial.println();
  
  inputString.reserve(200);
  
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(100);
    digitalWrite(LED_PIN, LOW);
    delay(100);
  }
}

void loop() {
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
  
  if (stringComplete) {
    processCommand(inputString);
    inputString = "";
    stringComplete = false;
  }
  
  if (currentMotor1Percent > 0 || currentMotor2Percent > 0) {
    digitalWrite(LED_PIN, (millis() / 300) % 2);
  } else {
    digitalWrite(LED_PIN, LOW);
  }
}

void printHeader() {
  Serial.println();
  Serial.println("=========================================");
  Serial.println("  MD22 DUAL MOTOR CONTROLLER");
  Serial.println("  Address: 0x58 (All DIP switches ON)");
  Serial.println("=========================================");
  Serial.println();
}

void printCommands() {
  Serial.println("Available Commands:");
  Serial.println("  M1:0-100      - Set Motor1 speed");
  Serial.println("  M2:0-100      - Set Motor2 speed");
  Serial.println("  M1_STOP       - Stop Motor1");
  Serial.println("  M2_STOP       - Stop Motor2");
  Serial.println("  STOP_ALL      - Stop both motors");
  Serial.println();
  Serial.println("  TEST_M1       - Test Motor1");
  Serial.println("  TEST_M2       - Test Motor2");
  Serial.println("  TEST_BOTH     - Test both motors");
  Serial.println();
  Serial.println("  DIAG          - Full diagnostics");
  Serial.println("  STATUS        - Current status");
  Serial.println("  PING          - Test connection");
  Serial.println();
}

void initMD22() {
  Serial.println("Initializing MD22...");
  Serial.println("-----------------------------------------");
  
  Serial.print("  Testing address 0x58... ");
  Wire.beginTransmission(MD22_ADDRESS);
  byte error = Wire.endTransmission();
  
  if (error != 0) {
    Serial.println("FAILED!");
    Serial.print("  I2C error code: ");
    Serial.println(error);
    md22Available = false;
    return;
  }
  
  Serial.println("FOUND!");
  md22Available = true;
  
  Serial.print("  Reading software version... ");
  md22SoftwareVersion = readMD22Register(MD22_VERSION_REG);
  Serial.println(md22SoftwareVersion);
  
  Serial.print("  Setting Mode 0... ");
  writeMD22Register(MD22_MODE_REG, 0);
  delay(100);
  byte modeCheck = readMD22Register(MD22_MODE_REG);
  Serial.print("Done (verified: ");
  Serial.print(modeCheck);
  Serial.println(")");
  
  Serial.print("  Setting acceleration to 10... ");
  writeMD22Register(MD22_ACCELERATION_REG, 10);
  delay(50);
  Serial.println("Done");
  
  Serial.print("  Stopping both motors... ");
  stopAllMotors();
  delay(50);
  Serial.println("Done");
  
  Serial.println();
  Serial.println("MD22 initialized successfully!");
  Serial.println();
}

void writeMD22Register(byte reg, byte value) {
  Wire.beginTransmission(MD22_ADDRESS);
  Wire.write(reg);
  Wire.write(value);
  Wire.endTransmission();
  delay(5);
}

byte readMD22Register(byte reg) {
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

byte percentToMD22Value(int percent) {
  percent = constrain(percent, MOTOR_MIN_PERCENT, MOTOR_MAX_PERCENT);
  
  if (percent == 0) {
    return MD22_STOP;
  }
  
  int value = MD22_STOP + ((percent * (MD22_FULL_FORWARD - MD22_STOP)) / 100);
  return (byte)constrain(value, MD22_STOP, MD22_FULL_FORWARD);
}

void setMotor1Speed(int percent) {
  if (!md22Available) {
    Serial.println("ERROR: MD22 not available");
    return;
  }
  
  percent = constrain(percent, MOTOR_MIN_PERCENT, MOTOR_MAX_PERCENT);
  byte md22Value = percentToMD22Value(percent);
  
  writeMD22Register(MD22_MOTOR1_REG, md22Value);
  delay(10);
  
  byte readBack = readMD22Register(MD22_MOTOR1_REG);
  
  currentMotor1Percent = percent;
  currentMotor1Value = readBack;
  
  Serial.print("M1: ");
  Serial.print(percent);
  Serial.print("% = MD22 value ");
  Serial.print(md22Value);
  Serial.print(" (read back: ");
  Serial.print(readBack);
  Serial.println(")");
}

void setMotor2Speed(int percent) {
  if (!md22Available) {
    Serial.println("ERROR: MD22 not available");
    return;
  }
  
  percent = constrain(percent, MOTOR_MIN_PERCENT, MOTOR_MAX_PERCENT);
  byte md22Value = percentToMD22Value(percent);
  
  writeMD22Register(MD22_MOTOR2_REG, md22Value);
  delay(10);
  
  byte readBack = readMD22Register(MD22_MOTOR2_REG);
  
  currentMotor2Percent = percent;
  currentMotor2Value = readBack;
  
  Serial.print("M2: ");
  Serial.print(percent);
  Serial.print("% = MD22 value ");
  Serial.print(md22Value);
  Serial.print(" (read back: ");
  Serial.print(readBack);
  Serial.println(")");
}

void stopMotor1() {
  Serial.print("Stopping Motor1... ");
  setMotor1Speed(0);
}

void stopMotor2() {
  Serial.print("Stopping Motor2... ");
  setMotor2Speed(0);
}

void stopAllMotors() {
  writeMD22Register(MD22_MOTOR1_REG, MD22_STOP);
  delay(10);
  writeMD22Register(MD22_MOTOR2_REG, MD22_STOP);
  delay(10);
  
  currentMotor1Percent = 0;
  currentMotor2Percent = 0;
  currentMotor1Value = MD22_STOP;
  currentMotor2Value = MD22_STOP;
}

void processCommand(String command) {
  command.trim();
  command.toUpperCase();
  
  if (command == "PING") {
    Serial.println("PONG - MD22 connected at 0x58");
    return;
  }
  
  if (command == "STATUS") {
    Serial.println("=== STATUS ===");
    Serial.print("MD22: ");
    Serial.println(md22Available ? "Connected at 0x58" : "Disconnected");
    
    if (!md22Available) {
      Serial.println("==============");
      return;
    }
    
    byte mode = readMD22Register(MD22_MODE_REG);
    byte m1 = readMD22Register(MD22_MOTOR1_REG);
    byte m2 = readMD22Register(MD22_MOTOR2_REG);
    byte accel = readMD22Register(MD22_ACCELERATION_REG);
    byte ver = readMD22Register(MD22_VERSION_REG);
    
    Serial.print("Software version: ");
    Serial.println(ver);
    
    Serial.print("Mode: ");
    Serial.print(mode);
    if (mode != 0) {
      Serial.println(" WARNING - Should be 0!");
    } else {
      Serial.println(" OK");
    }
    
    Serial.print("Acceleration: ");
    Serial.println(accel);
    
    Serial.print("Motor1: ");
    Serial.print(currentMotor1Percent);
    Serial.print("% | Live: ");
    Serial.println(m1);
    
    Serial.print("Motor2: ");
    Serial.print(currentMotor2Percent);
    Serial.print("% | Live: ");
    Serial.println(m2);
    
    Serial.println("==============");
    return;
  }
  
  if (command == "DIAG") {
    runDiagnostics();
    return;
  }
  
  if (command == "M1_STOP") {
    stopMotor1();
    return;
  }
  
  if (command == "M2_STOP") {
    stopMotor2();
    return;
  }
  
  if (command == "STOP_ALL") {
    Serial.println("Stopping all motors...");
    stopAllMotors();
    Serial.println("All motors stopped");
    return;
  }
  
  if (command == "TEST_M1") {
    testMotor1();
    return;
  }
  
  if (command == "TEST_M2") {
    testMotor2();
    return;
  }
  
  if (command == "TEST_BOTH") {
    testBothMotors();
    return;
  }
  
  if (command.startsWith("M1:")) {
    int percent = command.substring(3).toInt();
    if (percent >= MOTOR_MIN_PERCENT && percent <= MOTOR_MAX_PERCENT) {
      setMotor1Speed(percent);
    } else {
      Serial.print("ERROR: M1 out of range: ");
      Serial.println(percent);
    }
    return;
  }
  
  if (command.startsWith("M2:")) {
    int percent = command.substring(3).toInt();
    if (percent >= MOTOR_MIN_PERCENT && percent <= MOTOR_MAX_PERCENT) {
      setMotor2Speed(percent);
    } else {
      Serial.print("ERROR: M2 out of range: ");
      Serial.println(percent);
    }
    return;
  }
  
  Serial.print("ERROR: Unknown command: ");
  Serial.println(command);
}

void testMotor1() {
  Serial.println();
  Serial.println("=== TESTING MOTOR 1 ===");
  
  int testSpeeds[] = {0, 20, 40, 60, 80, 100, 80, 60, 40, 20, 0};
  int numSteps = sizeof(testSpeeds) / sizeof(testSpeeds[0]);
  
  for (int i = 0; i < numSteps; i++) {
    Serial.print("Step ");
    Serial.print(i + 1);
    Serial.print("/");
    Serial.print(numSteps);
    Serial.print(": ");
    setMotor1Speed(testSpeeds[i]);
    delay(2000);
  }
  
  Serial.println("=== MOTOR 1 TEST COMPLETE ===");
  Serial.println();
}

void testMotor2() {
  Serial.println();
  Serial.println("=== TESTING MOTOR 2 ===");
  
  int testSpeeds[] = {0, 20, 40, 60, 80, 100, 80, 60, 40, 20, 0};
  int numSteps = sizeof(testSpeeds) / sizeof(testSpeeds[0]);
  
  for (int i = 0; i < numSteps; i++) {
    Serial.print("Step ");
    Serial.print(i + 1);
    Serial.print("/");
    Serial.print(numSteps);
    Serial.print(": ");
    setMotor2Speed(testSpeeds[i]);
    delay(2000);
  }
  
  Serial.println("=== MOTOR 2 TEST COMPLETE ===");
  Serial.println();
}

void testBothMotors() {
  Serial.println();
  Serial.println("=== TESTING BOTH MOTORS ===");
  
  int testSpeeds[] = {0, 30, 60, 100, 60, 30, 0};
  int numSteps = sizeof(testSpeeds) / sizeof(testSpeeds[0]);
  
  for (int i = 0; i < numSteps; i++) {
    Serial.print("Step ");
    Serial.print(i + 1);
    Serial.print("/");
    Serial.print(numSteps);
    Serial.println(":");
    setMotor1Speed(testSpeeds[i]);
    setMotor2Speed(testSpeeds[i]);
    Serial.println();
    delay(2000);
  }
  
  Serial.println("=== BOTH MOTORS TEST COMPLETE ===");
  Serial.println();
}

void runDiagnostics() {
  Serial.println();
  Serial.println("=== FULL DIAGNOSTICS ===");
  
  if (!md22Available) {
    Serial.println("ERROR: MD22 not available");
    return;
  }
  
  Serial.println("Reading all MD22 registers:");
  Serial.println();
  
  byte mode = readMD22Register(MD22_MODE_REG);
  Serial.print("  Register 0x00 (Mode): ");
  Serial.println(mode);
  
  byte m1 = readMD22Register(MD22_MOTOR1_REG);
  Serial.print("  Register 0x01 (Motor1): ");
  Serial.println(m1);
  
  byte m2 = readMD22Register(MD22_MOTOR2_REG);
  Serial.print("  Register 0x02 (Motor2): ");
  Serial.println(m2);
  
  byte accel = readMD22Register(MD22_ACCELERATION_REG);
  Serial.print("  Register 0x03 (Acceleration): ");
  Serial.println(accel);
  
  byte ver = readMD22Register(MD22_VERSION_REG);
  Serial.print("  Register 0x07 (Version): ");
  Serial.println(ver);
  
  Serial.println();
  Serial.println("Current state:");
  Serial.print("  Motor1: ");
  Serial.print(currentMotor1Percent);
  Serial.println("%");
  Serial.print("  Motor2: ");
  Serial.print(currentMotor2Percent);
  Serial.println("%");
  
  Serial.println("=== DIAGNOSTICS COMPLETE ===");
  Serial.println();
}
