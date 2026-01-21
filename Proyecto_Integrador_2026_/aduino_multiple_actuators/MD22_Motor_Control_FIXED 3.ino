/*
 * MD22 DUAL MOTOR CONTROLLER - CORRECTED VERSION
 * 
 * CONFIGURATION:
 * - DIP Switches: 1,2,3,4 ALL ON
 * - I2C Address: 0x58 (Datasheet shows 0xB0, Arduino uses 7-bit: 0xB0 >> 1 = 0x58)
 * 
 * FIXES APPLIED:
 * 1. Corrected I2C address from 0x5E to 0x58 for all switches ON
 * 2. Fixed all register addresses per MD22 datasheet
 * 3. Corrected diagnostics to read proper registers
 * 4. Added robust motor control with verification
 * 5. Added comprehensive testing functions
 * 
 * Hardware Connections:
 * - Arduino Mega Pin 20 (SDA) -> MD22 SDA
 * - Arduino Mega Pin 21 (SCL) -> MD22 SCL
 * - Arduino 5V -> MD22 5V (logic side)
 * - Arduino GND -> MD22 GND (COMMON GROUND - both logic and motor side!)
 * - External 12V -> MD22 12V (motor side power)
 * - Motor 1 -> MD22 M1A, M1B terminals
 * - Motor 2 -> MD22 M2A, M2B terminals
 * 
 * Serial Commands (115200 baud):
 *   M1:percent      - Set Motor1 speed 0-100% (e.g., M1:50)
 *   M2:percent      - Set Motor2 speed 0-100% (e.g., M2:30)
 *   M1_STOP         - Stop Motor1
 *   M2_STOP         - Stop Motor2
 *   STOP_ALL        - Stop both motors
 *   
 *   TEST_M1         - Test Motor1 at multiple speeds
 *   TEST_M2         - Test Motor2 at multiple speeds
 *   TEST_BOTH       - Test both motors simultaneously
 *   
 *   DIAG            - Show all MD22 registers
 *   READ_MOTORS     - Read current motor speeds from MD22
 *   PING            - Test connection
 *   STATUS          - Show current state
 */

#include <Wire.h>

// ============================================================================
// MD22 CONFIGURATION - ALL CORRECTED PER DATASHEET
// ============================================================================

// I2C Address: DIP switches 1,2,3,4 ALL ON = 0xB0 (datasheet) = 0x58 (Arduino 7-bit)
const byte MD22_ADDRESS = 0x58;

// Register addresses (CORRECTED - see MD22 datasheet page)
const byte MD22_MODE_REG = 0x00;             // Mode register (MUST set to 0)
const byte MD22_MOTOR1_REG = 0x01;           // Motor 1 speed (called "Speed" in datasheet)
const byte MD22_MOTOR2_REG = 0x02;           // Motor 2 speed (called "Speed2/Turn" in datasheet)
const byte MD22_ACCELERATION_REG = 0x03;     // Acceleration register
// Registers 0x04, 0x05, 0x06 are unused (read as zero)
const byte MD22_VERSION_REG = 0x07;          // Software revision number

// MD22 Mode 0 speed values
const byte MD22_STOP = 128;                  // Stop (neutral)
const byte MD22_FULL_FORWARD = 255;          // Maximum forward
const byte MD22_FULL_REVERSE = 0;            // Maximum reverse

// Speed range (0-100% forward only for now)
const int MOTOR_MIN_PERCENT = 0;
const int MOTOR_MAX_PERCENT = 100;

// ============================================================================
// STATE VARIABLES
// ============================================================================

int currentMotor1Percent = 0;                // Current Motor1 speed (0-100%)
int currentMotor2Percent = 0;                // Current Motor2 speed (0-100%)
byte currentMotor1Value = MD22_STOP;         // Current MD22 value for Motor1
byte currentMotor2Value = MD22_STOP;         // Current MD22 value for Motor2

bool md22Available = false;
byte md22SoftwareVersion = 0;

String inputString = "";
boolean stringComplete = false;

const int LED_PIN = 13;

// ============================================================================
// SETUP
// ============================================================================

void setup() {
  Serial.begin(115200);
  while (!Serial);
  
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  delay(1000);
  
  printHeader();
  
  // Initialize I2C
  Wire.begin();
  delay(100);
  
  // Initialize MD22
  initMD22();
  
  if (md22Available) {
    printCommands();
  } else {
    Serial.println("ERROR: MD22 initialization failed!");
    Serial.println("Check connections and power.");
    Serial.println();
    Serial.println("Troubleshooting:");
    Serial.println("1. Verify all 4 DIP switches are ON");
    Serial.println("2. Check 5V power to MD22 logic side");
    Serial.println("3. Check SDA/SCL connections (pins 20/21)");
    Serial.println("4. Ensure common ground between Arduino and MD22");
  }
  
  Serial.println("=========================================");
  Serial.println();
  
  inputString.reserve(200);
  
  // Flash LED to indicate ready
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(100);
    digitalWrite(LED_PIN, LOW);
    delay(100);
  }
}

// ============================================================================
// MAIN LOOP
// ============================================================================

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
  
  // Process commands
  if (stringComplete) {
    processCommand(inputString);
    inputString = "";
    stringComplete = false;
  }
  
  // Blink LED when either motor running
  if (currentMotor1Percent > 0 || currentMotor2Percent > 0) {
    digitalWrite(LED_PIN, (millis() / 300) % 2);
  } else {
    digitalWrite(LED_PIN, LOW);
  }
}

// ============================================================================
// DISPLAY FUNCTIONS
// ============================================================================

void printHeader() {
  Serial.println();
  Serial.println("=========================================");
  Serial.println("  MD22 DUAL MOTOR CONTROLLER");
  Serial.println("  ** CORRECTED VERSION **");
  Serial.println("  Address: 0x58 (All DIP switches ON)");
  Serial.println("=========================================");
  Serial.println();
}

void printCommands() {
  Serial.println("Available Commands:");
  Serial.println("  M1:0-100      - Set Motor1 speed (e.g., M1:50)");
  Serial.println("  M2:0-100      - Set Motor2 speed (e.g., M2:50)");
  Serial.println("  M1_STOP       - Stop Motor1");
  Serial.println("  M2_STOP       - Stop Motor2");
  Serial.println("  STOP_ALL      - Stop both motors");
  Serial.println();
  Serial.println("  TEST_M1       - Test Motor1 sequence");
  Serial.println("  TEST_M2       - Test Motor2 sequence");
  Serial.println("  TEST_BOTH     - Test both motors");
  Serial.println();
  Serial.println("  DIAG          - Full diagnostics");
  Serial.println("  READ_MOTORS   - Read motor values");
  Serial.println("  PING          - Test connection");
  Serial.println("  STATUS        - Current status");
  Serial.println();
}

// ============================================================================
// MD22 INITIALIZATION
// ============================================================================

void initMD22() {
  Serial.println("Initializing MD22...");
  Serial.println("-----------------------------------------");
  
  // Test connection
  Serial.print("  Testing address 0x58 (all switches ON)... ");
  Wire.beginTransmission(MD22_ADDRESS);
  byte error = Wire.endTransmission();
  
  if (error != 0) {
    Serial.println("FAILED!");
    Serial.print("  I2C error code: ");
    Serial.println(error);
    Serial.println();
    Serial.println("  Possible issues:");
    Serial.println("  - DIP switches not all ON");
    Serial.println("  - No 5V power to MD22");
    Serial.println("  - SDA/SCL not connected");
    Serial.println("  - No common ground");
    md22Available = false;
    return;
  }
  
  Serial.println("FOUND!");
  md22Available = true;
  
  // Read software version FIRST (before setting mode)
  Serial.print("  Reading software version... ");
  md22SoftwareVersion = readMD22Register(MD22_VERSION_REG);
  Serial.print(md22SoftwareVersion);
  Serial.println(" (Good! MD22 is responding)");
  
  // CRITICAL: Set Mode to 0 (required for proper operation)
  Serial.print("  Setting Mode 0... ");
  writeMD22Register(MD22_MODE_REG, 0);
  delay(100);  // Give MD22 time to process mode change
  byte modeCheck = readMD22Register(MD22_MODE_REG);
  Serial.print("Done (verified: ");
  Serial.print(modeCheck);
  Serial.println(")");
  
  if (modeCheck != 0) {
    Serial.println("  WARNING: Mode may not be set correctly!");
  }
  
  // Set acceleration to moderate speed (10 = ~640us per step)
  Serial.print("  Setting acceleration to 10... ");
  writeMD22Register(MD22_ACCELERATION_REG, 10);
  delay(50);
  byte accelCheck = readMD22Register(MD22_ACCELERATION_REG);
  Serial.print("Done (verified: ");
  Serial.print(accelCheck);
  Serial.println(")");
  
  // Stop both motors (set to neutral position 128)
  Serial.print("  Stopping both motors... ");
  stopAllMotors();
  delay(50);
  Serial.println("Done");
  
  // Verify motors are stopped
  byte m1Check = readMD22Register(MD22_MOTOR1_REG);
  byte m2Check = readMD22Register(MD22_MOTOR2_REG);
  Serial.print("  Motor values: M1=");
  Serial.print(m1Check);
  Serial.print(" M2=");
  Serial.print(m2Check);
  Serial.println(" (should both be 128)");
  
  Serial.println();
  Serial.println("MD22 initialized successfully!");
  Serial.println("Motors are ready to be controlled.");
  Serial.println();
}

// ============================================================================
// MD22 I2C FUNCTIONS
// ============================================================================

void writeMD22Register(byte reg, byte value) {
  Wire.beginTransmission(MD22_ADDRESS);
  Wire.write(reg);
  Wire.write(value);
  Wire.endTransmission();
  delay(5);  // Small delay for MD22 to process
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

// ============================================================================
// MOTOR CONTROL FUNCTIONS
// ============================================================================

byte percentToMD22Value(int percent) {
  /*
   * Convert percentage (0-100) to MD22 Mode 0 value
   * Mode 0 range: 0=full reverse, 128=stop, 255=full forward
   * 
   * For forward-only control:
   * 0% -> 128 (stop)
   * 50% -> ~191 (half speed)
   * 100% -> 255 (full forward)
   */
  
  percent = constrain(percent, MOTOR_MIN_PERCENT, MOTOR_MAX_PERCENT);
  
  if (percent == 0) {
    return MD22_STOP;
  }
  
  // Linear mapping: 128 + (percent * 127 / 100)
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
  
  // Write to MD22
  writeMD22Register(MD22_MOTOR1_REG, md22Value);
  delay(10);
  
  // Read back to verify
  byte readBack = readMD22Register(MD22_MOTOR1_REG);
  
  currentMotor1Percent = percent;
  currentMotor1Value = readBack;
  
  Serial.print("M1: ");
  Serial.print(percent);
  Serial.print("% -> MD22 value ");
  Serial.print(md22Value);
  Serial.print(" (read back: ");
  Serial.print(readBack);
  
  if (readBack == md22Value) {
    Serial.println(") OK");
  } else {
    Serial.println(") WARNING MISMATCH!");
  }
}

void setMotor2Speed(int percent) {
  if (!md22Available) {
    Serial.println("ERROR: MD22 not available");
    return;
  }
  
  percent = constrain(percent, MOTOR_MIN_PERCENT, MOTOR_MAX_PERCENT);
  byte md22Value = percentToMD22Value(percent);
  
  // Write to MD22
  writeMD22Register(MD22_MOTOR2_REG, md22Value);
  delay(10);
  
  // Read back to verify
  byte readBack = readMD22Register(MD22_MOTOR2_REG);
  
  currentMotor2Percent = percent;
  currentMotor2Value = readBack;
  
  Serial.print("M2: ");
  Serial.print(percent);
  Serial.print("% -> MD22 value ");
  Serial.print(md22Value);
  Serial.print(" (read back: ");
  Serial.print(readBack);
  
  if (readBack == md22Value) {
    Serial.println(") OK");
  } else {
    Serial.println(") WARNING MISMATCH!");
  }
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

// ============================================================================
// COMMAND PROCESSING
// ============================================================================

void processCommand(String command) {
  command.trim();
  command.toUpperCase();
  
  // PING
  if (command == "PING") {
    Serial.println("PONG - MD22 " + String(md22Available ? "connected at 0x58" : "disconnected"));
    return;
  }
  
  // STATUS
  if (command == "STATUS") {
    Serial.println("=== STATUS ===");
    Serial.print("MD22: ");
    Serial.println(md22Available ? "Connected at 0x58" : "Disconnected");
    
    if (!md22Available) {
      Serial.println("==============");
      return;
    }
    
    // Read ALL critical registers LIVE
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
      Serial.println(" WARNING WARNING - Should be 0!");
    } else {
      Serial.println(" OK (Correct)");
    }
    
    Serial.print("Acceleration: ");
    Serial.print(accel);
    Serial.println(accel == 0 ? " (fastest)" : accel == 255 ? " (slowest)" : " (moderate)");
    
    Serial.print("Motor1: ");
    Serial.print(currentMotor1Percent);
    Serial.print("% | Live read: ");
    Serial.print(m1);
    if (m1 == 128) {
      Serial.println(" (STOPPED)");
    } else if (m1 > 128) {
      Serial.print(" (FORWARD ");
      Serial.print(map(m1, 128, 255, 0, 100));
      Serial.println("%)");
    } else {
      Serial.print(" (REVERSE ");
      Serial.print(map(m1, 0, 128, 100, 0));
      Serial.println("%)");
    }
    
    Serial.print("Motor2: ");
    Serial.print(currentMotor2Percent);
    Serial.print("% | Live read: ");
    Serial.print(m2);
    if (m2 == 128) {
      Serial.println(" (STOPPED)");
    } else if (m2 > 128) {
      Serial.print(" (FORWARD ");
      Serial.print(map(m2, 128, 255, 0, 100));
      Serial.println("%)");
    } else {
      Serial.print(" (REVERSE ");
      Serial.print(map(m2, 0, 128, 100, 0));
      Serial.println("%)");
    }
    
    Serial.println("==============");
    return;
  }
  
  // DIAG
  if (command == "DIAG") {
    runDiagnostics();
    return;
  }
  
  // READ_MOTORS
  if (command == "READ_MOTORS") {
    Serial.println("Reading motor values from MD22...");
    byte m1 = readMD22Register(MD22_MOTOR1_REG);
    byte m2 = readMD22Register(MD22_MOTOR2_REG);
    Serial.print("  Motor1 register (0x01): ");
    Serial.print(m1);
    Serial.println(m1 == 128 ? " (STOPPED)" : m1 > 128 ? " (FORWARD)" : " (REVERSE)");
    Serial.print("  Motor2 register (0x02): ");
    Serial.print(m2);
    Serial.println(m2 == 128 ? " (STOPPED)" : m2 > 128 ? " (FORWARD)" : " (REVERSE)");
    return;
  }
  
  // M1_STOP
  if (command == "M1_STOP") {
    stopMotor1();
    return;
  }
  
  // M2_STOP
  if (command == "M2_STOP") {
    stopMotor2();
    return;
  }
  
  // STOP_ALL
  if (command == "STOP_ALL") {
    Serial.println("Stopping all motors...");
    stopAllMotors();
    Serial.println("All motors stopped");
    return;
  }
  
  // TEST_M1
  if (command == "TEST_M1") {
    testMotor1();
    return;
  }
  
  // TEST_M2
  if (command == "TEST_M2") {
    testMotor2();
    return;
  }
  
  // TEST_BOTH
  if (command == "TEST_BOTH") {
    testBothMotors();
    return;
  }
  
  // M1:percent
  if (command.startsWith("M1:")) {
    int percent = command.substring(3).toInt();
    if (percent >= MOTOR_MIN_PERCENT && percent <= MOTOR_MAX_PERCENT) {
      setMotor1Speed(percent);
    } else {
      Serial.print("ERROR: M1 percent out of range (0-100): ");
      Serial.println(percent);
    }
    return;
  }
  
  // M2:percent
  if (command.startsWith("M2:")) {
    int percent = command.substring(3).toInt();
    if (percent >= MOTOR_MIN_PERCENT && percent <= MOTOR_MAX_PERCENT) {
      setMotor2Speed(percent);
    } else {
      Serial.print("ERROR: M2 percent out of range (0-100): ");
      Serial.println(percent);
    }
    return;
  }
  
  // Unknown command
  Serial.print("ERROR: Unknown command: ");
  Serial.println(command);
  Serial.println("Type one of: M1:0-100, M2:0-100, M1_STOP, M2_STOP, STOP_ALL, TEST_M1, TEST_M2, TEST_BOTH, DIAG, STATUS, PING");
}

// ============================================================================
// TEST FUNCTIONS
// ============================================================================

void testMotor1() {
  Serial.println();
  Serial.println("=== TESTING MOTOR 1 ===");
  Serial.println("Watch Motor 1 - it should ramp up slowly");
  Serial.println();
  
  int testSpeeds[] = {0, 20, 40, 60, 80, 100, 80, 60, 40, 20, 0};
  int numSteps = sizeof(testSpeeds) / sizeof(testSpeeds[0]);
  
  for (int i = 0; i < numSteps; i++) {
    Serial.print("Step ");
    Serial.print(i + 1);
    Serial.print("/");
    Serial.print(numSteps);
    Serial.print(": ");
    setMotor1Speed(testSpeeds[i]);
    delay(2000);  // Hold each speed for 2 seconds
  }
  
  Serial.println();
  Serial.println("=== MOTOR 1 TEST COMPLETE ===");
  Serial.println();
}

void testMotor2() {
  Serial.println();
  Serial.println("=== TESTING MOTOR 2 ===");
  Serial.println("Watch Motor 2 - it should ramp up slowly");
  Serial.println();
  
  int testSpeeds[] = {0, 20, 40, 60, 80, 100, 80, 60, 40, 20, 0};
  int numSteps = sizeof(testSpeeds) / sizeof(testSpeeds[0]);
  
  for (int i = 0; i < numSteps; i++) {
    Serial.print("Step ");
    Serial.print(i + 1);
    Serial.print("/");
    Serial.print(numSteps);
    Serial.print(": ");
    setMotor2Speed(testSpeeds[i]);
    delay(2000);  // Hold each speed for 2 seconds
  }
  
  Serial.println();
  Serial.println("=== MOTOR 2 TEST COMPLETE ===");
  Serial.println();
}

void testBothMotors() {
  Serial.println();
  Serial.println("=== TESTING BOTH MOTORS ===");
  Serial.println("Both motors should move together");
  Serial.println();
  
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
    Serial.println("Run initialization first or check connections");
    return;
  }
  
  Serial.println("Reading all MD22 registers:");
  Serial.println();
  
  // Register 0x00 - Mode
  byte mode = readMD22Register(MD22_MODE_REG);
  Serial.print("  Register 0x00 (Mode): ");
  Serial.print(mode);
  Serial.println(mode == 0 ? " OK (Mode 0 - correct)" : " WARNING (Should be 0!)");
  
  // Register 0x01 - Motor 1 Speed
  byte m1 = readMD22Register(MD22_MOTOR1_REG);
  Serial.print("  Register 0x01 (Motor1): ");
  Serial.print(m1);
  if (m1 == 128) {
    Serial.println(" (STOPPED)");
  } else if (m1 > 128) {
    Serial.print(" (FORWARD at ");
    Serial.print(map(m1, 128, 255, 0, 100));
    Serial.println("%)");
  } else {
    Serial.print(" (REVERSE at ");
    Serial.print(map(m1, 0, 128, 100, 0));
    Serial.println("%)");
  }
  
  // Register 0x02 - Motor 2 Speed
  byte m2 = readMD22Register(MD22_MOTOR2_REG);
  Serial.print("  Register 0x02 (Motor2): ");
  Serial.print(m2);
  if (m2 == 128) {
    Serial.println(" (STOPPED)");
  } else if (m2 > 128) {
    Serial.print(" (FORWARD at ");
    Serial.print(map(m2, 128, 255, 0, 100));
    Serial.println("%)");
  } else {
    Serial.print(" (REVERSE at ");
    Serial.print(map(m2, 0, 128, 100, 0));
    Serial.println("%)");
  }
  
  // Register 0x03 - Acceleration
  byte accel = readMD22Register(MD22_ACCELERATION_REG);
  Serial.print("  Register 0x03 (Acceleration): ");
  Serial.print(accel);
  Serial.println(accel == 0 ? " (fastest)" : accel == 255 ? " (slowest)" : " (moderate)");
  
  // Registers 0x04, 0x05, 0x06 - Unused
  Serial.println("  Registers 0x04-0x06: Unused (not read)");
  
  // Register 0x07 - Software Version
  byte ver = readMD22Register(MD22_VERSION_REG);
  Serial.print("  Register 0x07 (Software Version): ");
  Serial.println(ver);
  
  Serial.println();
  Serial.println("Current tracked state:");
  Serial.print("  Motor1: ");
  Serial.print(currentMotor1Percent);
  Serial.print("% (tracking value: ");
  Serial.print(currentMotor1Value);
  Serial.println(")");
  Serial.print("  Motor2: ");
  Serial.print(currentMotor2Percent);
  Serial.print("% (tracking value: ");
  Serial.print(currentMotor2Value);
  Serial.println(")");
  
  Serial.println();
  Serial.println("=== DIAGNOSTICS COMPLETE ===");
  Serial.println();
}
