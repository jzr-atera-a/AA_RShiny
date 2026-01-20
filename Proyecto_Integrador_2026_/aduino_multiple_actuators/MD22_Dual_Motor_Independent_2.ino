/*
 * MD22 DUAL MOTOR CONTROLLER - Full Range Independent Control
 * 
 * Verified Working:
 * - MD22 detected at address 0x58
 * - Software version: 10
 * - I2C communication: Working
 * - Motor side power: 10.5V confirmed
 * 
 * This version provides INDEPENDENT control of both motors
 * Range: 0-100% in 10% intervals
 * 
 * Hardware Connections:
 * - Arduino Mega Pin 20 (SDA) → MD22 SDA
 * - Arduino Mega Pin 21 (SCL) → MD22 SCL
 * - Arduino 5V → MD22 5V (logic side)
 * - Arduino GND → MD22 GND (both logic and motor side - COMMON GROUND!)
 * - External 12V → MD22 12V (motor side)
 * - Motor 1 → MD22 M1A, M1B terminals
 * - Motor 2 → MD22 M2A, M2B terminals
 * 
 * Serial Commands:
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
// MD22 CONFIGURATION
// ============================================================================

const byte MD22_ADDRESS = 0x5E;              // Switches 1+3 ON = 0xBC >> 1 = 0x5E
const byte MD22_MODE_REG = 0x00;             // Mode register (MUST set to 0)
const byte MD22_MOTOR1_REG = 0x01;           // Motor 1 speed register (Speed)
const byte MD22_MOTOR2_REG = 0x02;           // Motor 2 speed register (Speed2)
const byte MD22_ACCELERATION_REG = 0x03;     // Acceleration register
const byte MD22_VERSION_REG = 0x07;          // Software version
const byte MD22_VOLTAGE_REG = 0x0A;          // Battery voltage (may not exist on old MD22)

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
  Serial.println("  Independent Control - Full Range");
  Serial.println("=========================================");
  Serial.println();
}

void printCommands() {
  Serial.println("Available Commands:");
  Serial.println("  M1:0          - Motor1 at 0% (stopped)");
  Serial.println("  M1:10         - Motor1 at 10%");
  Serial.println("  M1:20         - Motor1 at 20%");
  Serial.println("  M1:30         - Motor1 at 30%");
  Serial.println("  M1:40         - Motor1 at 40%");
  Serial.println("  M1:50         - Motor1 at 50%");
  Serial.println("  M1:60         - Motor1 at 60%");
  Serial.println("  M1:70         - Motor1 at 70%");
  Serial.println("  M1:80         - Motor1 at 80%");
  Serial.println("  M1:90         - Motor1 at 90%");
  Serial.println("  M1:100        - Motor1 at 100% (full)");
  Serial.println();
  Serial.println("  M2:0          - Motor2 at 0% (stopped)");
  Serial.println("  M2:10         - Motor2 at 10%");
  Serial.println("  M2:20         - Motor2 at 20%");
  Serial.println("  M2:30         - Motor2 at 30%");
  Serial.println("  M2:40         - Motor2 at 40%");
  Serial.println("  M2:50         - Motor2 at 50%");
  Serial.println("  M2:60         - Motor2 at 60%");
  Serial.println("  M2:70         - Motor2 at 70%");
  Serial.println("  M2:80         - Motor2 at 80%");
  Serial.println("  M2:90         - Motor2 at 90%");
  Serial.println("  M2:100        - Motor2 at 100% (full)");
  Serial.println();
  Serial.println("  M1_STOP       - Stop Motor1");
  Serial.println("  M2_STOP       - Stop Motor2");
  Serial.println("  STOP_ALL      - Stop both motors");
  Serial.println();
  Serial.println("  DIAG          - Full diagnostics");
  Serial.println("  READ_MOTORS   - Read motor values from MD22");
  Serial.println("  PING          - Test connection");
  Serial.println("  STATUS        - Current status");
  Serial.println();
  Serial.println("MANUAL CONTROL ONLY - You control every command");
  Serial.println();
}

// ============================================================================
// MD22 INITIALIZATION
// ============================================================================

void initMD22() {
  Serial.println("Initializing MD22...");
  Serial.println("-----------------------------------------");
  
  // Test connection
  Serial.print("  Checking address 0x5E (switches 1+3 ON)... ");
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
  
  // CRITICAL: Set Mode to 0 FIRST (required for old MD22)
  Serial.print("  Setting Mode 0 (CRITICAL)... ");
  writeMD22Register(MD22_MODE_REG, 0);
  delay(100);  // Give MD22 time to process
  byte modeCheck = readMD22Register(MD22_MODE_REG);
  Serial.print("Done (read back: ");
  Serial.print(modeCheck);
  Serial.println(")");
  
  // Read software version
  Serial.print("  Software version: ");
  md22SoftwareVersion = readMD22Register(MD22_VERSION_REG);
  Serial.println(md22SoftwareVersion);
  
  // Set acceleration to slowest (255 for gradual ramp-up)
  Serial.print("  Setting acceleration to 10 (moderate)... ");
  writeMD22Register(MD22_ACCELERATION_REG, 10);
  delay(50);
  byte accelCheck = readMD22Register(MD22_ACCELERATION_REG);
  Serial.print("Done (read back: ");
  Serial.print(accelCheck);
  Serial.println(")");
  
  // Stop both motors
  Serial.print("  Stopping both motors... ");
  stopAllMotors();
  delay(50);
  Serial.println("Done");
  
  Serial.println("MD22 initialized successfully!");
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
   * 0% → 128 (stop)
   * 50% → ~191 (half speed)
   * 100% → 255 (full forward)
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
  Serial.print("% → MD22 value ");
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
  
  // Write to MD22
  writeMD22Register(MD22_MOTOR2_REG, md22Value);
  delay(10);
  
  // Read back to verify
  byte readBack = readMD22Register(MD22_MOTOR2_REG);
  
  currentMotor2Percent = percent;
  currentMotor2Value = readBack;
  
  Serial.print("M2: ");
  Serial.print(percent);
  Serial.print("% → MD22 value ");
  Serial.print(md22Value);
  Serial.print(" (read back: ");
  Serial.print(readBack);
  Serial.println(")");
}

void stopMotor1() {
  setMotor1Speed(0);
}

void stopMotor2() {
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
    Serial.println("PONG - MD22 " + String(md22Available ? "connected" : "disconnected"));
    return;
  }
  
  // STATUS
  if (command == "STATUS") {
    Serial.println("=== STATUS ===");
    Serial.print("MD22: ");
    Serial.println(md22Available ? "Connected" : "Disconnected");
    Serial.print("Motor1: ");
    Serial.print(currentMotor1Percent);
    Serial.print("% (MD22: ");
    Serial.print(currentMotor1Value);
    Serial.println(")");
    Serial.print("Motor2: ");
    Serial.print(currentMotor2Percent);
    Serial.print("% (MD22: ");
    Serial.print(currentMotor2Value);
    Serial.println(")");
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
    Serial.print("  Motor1 register: ");
    Serial.println(m1);
    Serial.print("  Motor2 register: ");
    Serial.println(m2);
    return;
  }
  
  // M1_STOP
  if (command == "M1_STOP") {
    stopMotor1();
    Serial.println("Motor1 stopped");
    return;
  }
  
  // M2_STOP
  if (command == "M2_STOP") {
    stopMotor2();
    Serial.println("Motor2 stopped");
    return;
  }
  
  // STOP_ALL
  if (command == "STOP_ALL") {
    stopAllMotors();
    Serial.println("All motors stopped");
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
  Serial.println("Valid: M1:0-100, M2:0-100, M1_STOP, M2_STOP, STOP_ALL, DIAG, STATUS, PING");
}

// ============================================================================
// TEST FUNCTIONS
// ============================================================================

void runDiagnostics() {
  Serial.println("=== FULL DIAGNOSTICS ===");
  
  if (!md22Available) {
    Serial.println("ERROR: MD22 not available");
    return;
  }
  
  Serial.println("Reading all MD22 registers:");
  Serial.println();
  
  byte m1 = readMD22Register(MD22_MOTOR1_REG);
  Serial.print("  Motor1 Speed (0x00): ");
  Serial.print(m1);
  Serial.print(" (128=stop, >128=forward)");
  Serial.println();
  
  byte m2 = readMD22Register(MD22_MOTOR2_REG);
  Serial.print("  Motor2 Speed (0x01): ");
  Serial.print(m2);
  Serial.print(" (128=stop, >128=forward)");
  Serial.println();
  
  byte ver = readMD22Register(MD22_VERSION_REG);
  Serial.print("  Software Version (0x07): ");
  Serial.println(ver);
  
  byte volt = readMD22Register(MD22_VOLTAGE_REG);
  Serial.print("  Battery Voltage (0x0A): ");
  Serial.print(volt / 10.0);
  Serial.println("V");
  
  byte accel = readMD22Register(MD22_ACCELERATION_REG);
  Serial.print("  Acceleration (0x0E): ");
  Serial.println(accel);
  
  byte mode = readMD22Register(MD22_MODE_REG);
  Serial.print("  Mode (0x0F): ");
  Serial.print(mode);
  Serial.println(" (should be 0)");
  
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
