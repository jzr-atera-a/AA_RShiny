/*
 * MD22 Single Motor Controller - VERIFIED WORKING
 * 
 * Based on successful I2C scan results:
 * - MD22 detected at address 0x58
 * - Software version: 10
 * - Communication confirmed working
 * 
 * This code controls MD22 Motor1 from 0-33% forward speed only
 * 
 * Hardware Connections:
 * - Arduino Mega Pin 20 (SDA) → MD22 SDA
 * - Arduino Mega Pin 21 (SCL) → MD22 SCL
 * - Arduino 5V → MD22 5V (logic side)
 * - Arduino GND → MD22 GND (logic side + motor side, common ground)
 * - External 12V → MD22 12V (motor side)
 * - DC Motor → MD22 Motor1 terminals (M1A, M1B)
 * 
 * MD22 I2C Registers:
 * - 0x00: Motor1 speed (0-255, 128=stop)
 * - 0x01: Motor2 speed (0-255, 128=stop)
 * - 0x07: Software version (read only)
 * - 0x0F: Mode register
 * 
 * MD22 Mode 0 (default):
 * - 0 = Full reverse
 * - 128 = Stop
 * - 255 = Full forward
 * 
 * Serial Commands:
 *   MOTOR1:speed   - Set motor1 speed (0-33% forward)
 *   MOTOR1_STOP    - Stop motor1
 *   PING           - Test connection
 *   STATUS         - Show current status
 */

#include <Wire.h>

// ============================================================================
// MD22 CONFIGURATION
// ============================================================================

const byte MD22_ADDRESS = 0x58;        // Confirmed by scanner
const byte MD22_MOTOR1_REG = 0x00;     // Motor 1 speed register
const byte MD22_MOTOR2_REG = 0x01;     // Motor 2 speed register
const byte MD22_MODE_REG = 0x0F;       // Mode register
const byte MD22_VERSION_REG = 0x07;    // Software version register

// MD22 Mode 0 values
const byte MD22_STOP = 128;            // Stop value
const byte MD22_FULL_FORWARD = 255;    // Maximum forward
const byte MD22_FULL_REVERSE = 0;      // Maximum reverse

// Speed limits (0-33% forward only)
const int MOTOR_MIN_PERCENT = 0;
const int MOTOR_MAX_PERCENT = 33;

// ============================================================================
// STATE VARIABLES
// ============================================================================

int currentMotor1Speed = 0;            // Current speed (0-33%)
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
  
  Serial.println();
  Serial.println("=====================================");
  Serial.println("  MD22 Motor Controller - VERIFIED");
  Serial.println("=====================================");
  Serial.println();
  
  // Initialize I2C
  Wire.begin();
  delay(100);
  
  // Initialize MD22
  initMD22();
  
  if (md22Available) {
    Serial.println("Commands:");
    Serial.println("  MOTOR1:speed  - Set speed 0-33% (e.g., MOTOR1:20)");
    Serial.println("  MOTOR1_STOP   - Stop motor");
    Serial.println("  PING          - Test connection");
    Serial.println("  STATUS        - Show current status");
    Serial.println();
    Serial.println("Motor1 ready! Speed range: 0-33% forward");
  } else {
    Serial.println("ERROR: MD22 not responding!");
    Serial.println("Check connections and run scanner again.");
  }
  
  Serial.println("=====================================");
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
  
  // Blink LED when motor running
  if (currentMotor1Speed > 0) {
    digitalWrite(LED_PIN, (millis() / 500) % 2);
  } else {
    digitalWrite(LED_PIN, LOW);
  }
}

// ============================================================================
// MD22 INITIALIZATION
// ============================================================================

void initMD22() {
  Serial.println("Initializing MD22...");
  Serial.print("  Searching at address 0x58... ");
  
  // Test connection
  Wire.beginTransmission(MD22_ADDRESS);
  byte error = Wire.endTransmission();
  
  if (error == 0) {
    Serial.println("FOUND!");
    md22Available = true;
    
    // Read software version
    Serial.print("  Reading software version... ");
    Wire.beginTransmission(MD22_ADDRESS);
    Wire.write(MD22_VERSION_REG);
    Wire.endTransmission();
    
    delay(10);
    Wire.requestFrom(MD22_ADDRESS, (byte)1);
    if (Wire.available()) {
      md22SoftwareVersion = Wire.read();
      Serial.print("Version ");
      Serial.println(md22SoftwareVersion);
    } else {
      Serial.println("Failed to read");
    }
    
    // Set to Mode 0 (should be default, but let's be sure)
    Serial.print("  Setting Mode 0... ");
    writeMD22Register(MD22_MODE_REG, 0);
    delay(50);
    Serial.println("Done");
    
    // Stop motor on startup
    Serial.print("  Stopping motor... ");
    stopMotor1();
    delay(50);
    Serial.println("Done");
    
    Serial.println("MD22 initialized successfully!");
    
  } else {
    Serial.println("NOT FOUND!");
    Serial.print("  I2C error code: ");
    Serial.println(error);
    md22Available = false;
  }
  
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

byte percentToMD22Speed(int percent) {
  /*
   * Convert percentage (0-33) to MD22 speed value
   * 0% → 128 (stop)
   * 33% → 170 (33% of forward range)
   * 
   * Forward range: 128-255 (127 steps)
   * 33% of 127 = 42 steps
   * So: 128 + (percent * 42 / 33)
   */
  
  // Clamp to valid range
  percent = constrain(percent, MOTOR_MIN_PERCENT, MOTOR_MAX_PERCENT);
  
  if (percent == 0) {
    return MD22_STOP;
  }
  
  // Calculate MD22 value
  int forwardRange = MD22_FULL_FORWARD - MD22_STOP;  // 127
  int allowedSteps = (forwardRange * MOTOR_MAX_PERCENT) / 100;  // 42
  byte md22Speed = MD22_STOP + ((percent * allowedSteps) / MOTOR_MAX_PERCENT);
  
  return md22Speed;
}

void setMotor1Speed(int percent) {
  if (!md22Available) {
    Serial.println("ERROR: MD22 not available");
    return;
  }
  
  // Clamp to valid range
  percent = constrain(percent, MOTOR_MIN_PERCENT, MOTOR_MAX_PERCENT);
  
  // Convert to MD22 value
  byte md22Speed = percentToMD22Speed(percent);
  
  // Send to MD22
  writeMD22Register(MD22_MOTOR1_REG, md22Speed);
  currentMotor1Speed = percent;
  
  Serial.print("Motor1 speed set to ");
  Serial.print(percent);
  Serial.print("% (MD22 value: ");
  Serial.print(md22Speed);
  Serial.println(")");
}

void stopMotor1() {
  if (!md22Available) {
    return;
  }
  
  writeMD22Register(MD22_MOTOR1_REG, MD22_STOP);
  currentMotor1Speed = 0;
  Serial.println("Motor1 stopped");
}

// ============================================================================
// COMMAND PROCESSING
// ============================================================================

void processCommand(String command) {
  command.trim();
  command.toUpperCase();
  
  // PING command
  if (command == "PING") {
    Serial.println("PONG");
    if (md22Available) {
      Serial.println("MD22 connected and responsive");
    } else {
      Serial.println("MD22 not available");
    }
    return;
  }
  
  // STATUS command
  if (command == "STATUS") {
    Serial.println("=== STATUS ===");
    Serial.print("MD22 Address: 0x58 - ");
    Serial.println(md22Available ? "Connected" : "Disconnected");
    
    if (md22Available) {
      Serial.print("Software Version: ");
      Serial.println(md22SoftwareVersion);
      Serial.print("Motor1 Speed: ");
      Serial.print(currentMotor1Speed);
      Serial.println("%");
      
      // Read actual register value
      byte actualSpeed = readMD22Register(MD22_MOTOR1_REG);
      Serial.print("MD22 Register Value: ");
      Serial.print(actualSpeed);
      Serial.print(" (128=stop, 128-170=forward 0-33%)");
      Serial.println();
    }
    Serial.println("==============");
    return;
  }
  
  // MOTOR1_STOP command
  if (command == "MOTOR1_STOP") {
    stopMotor1();
    Serial.println("OK: Motor1 stopped");
    return;
  }
  
  // MOTOR1:speed command
  if (command.startsWith("MOTOR1:")) {
    int speed = command.substring(7).toInt();
    
    if (speed >= MOTOR_MIN_PERCENT && speed <= MOTOR_MAX_PERCENT) {
      setMotor1Speed(speed);
      Serial.print("OK: Motor1 set to ");
      Serial.print(speed);
      Serial.println("%");
    } else {
      Serial.print("ERROR: Speed out of range (");
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
  Serial.println("Valid commands: MOTOR1:0-33, MOTOR1_STOP, PING, STATUS");
}
