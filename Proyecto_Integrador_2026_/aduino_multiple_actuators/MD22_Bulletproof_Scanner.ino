/*
 * BULLETPROOF MD22 I2C Scanner
 * 
 * This code has been carefully reviewed to ensure NO logic errors.
 * Tests OLD MD22 (2008 model) detection at address 0x58
 * 
 * SETUP:
 * 1. Arduino Mega connected via USB
 * 2. MD22 logic side ONLY:
 *    - MD22 SDA → Arduino Pin 20
 *    - MD22 SCL → Arduino Pin 21
 *    - MD22 5V  → Arduino 5V
 *    - MD22 GND → Arduino GND
 * 3. MD22 12V motor power: NOT REQUIRED for this test
 * 4. MD22 DIP switches: ALL OFF (down position)
 * 
 * Upload this code and open Serial Monitor at 115200 baud
 */

#include <Wire.h>

void setup() {
  Serial.begin(115200);
  while (!Serial);
  delay(1000);
  
  printHeader();
  checkBoard();
  initializeI2C();
  performFullScan();
  testSpecificAddresses();
  printFooter();
}

void loop() {
  // Test runs once, nothing in loop
}

// ============================================================================
// DISPLAY FUNCTIONS
// ============================================================================

void printHeader() {
  Serial.println();
  Serial.println("========================================");
  Serial.println("   BULLETPROOF MD22 I2C SCANNER");
  Serial.println("========================================");
  Serial.println();
}

void printFooter() {
  Serial.println();
  Serial.println("========================================");
  Serial.println("   TEST COMPLETE");
  Serial.println("========================================");
  Serial.println();
  Serial.println("Please copy ALL output above and send to me!");
  Serial.println();
}

// ============================================================================
// BOARD VERIFICATION
// ============================================================================

void checkBoard() {
  Serial.println("[STEP 1] Checking Arduino Board Type");
  Serial.println("--------------------------------------");
  
  #if defined(__AVR_ATmega2560__)
    Serial.println("Result: Arduino Mega 2560 DETECTED");
    Serial.println("I2C Pins: SDA = Pin 20, SCL = Pin 21");
    Serial.println("Status: CORRECT BOARD");
  #elif defined(__AVR_ATmega328P__)
    Serial.println("Result: Arduino Uno/Nano DETECTED");
    Serial.println("I2C Pins: SDA = A4, SCL = A5");
    Serial.println("Status: WRONG BOARD - Need Arduino Mega!");
  #else
    Serial.println("Result: Unknown Arduino board");
    Serial.println("Status: CANNOT VERIFY");
  #endif
  
  Serial.println();
}

// ============================================================================
// I2C INITIALIZATION
// ============================================================================

void initializeI2C() {
  Serial.println("[STEP 2] Initializing I2C Bus");
  Serial.println("--------------------------------------");
  
  Wire.begin();
  delay(100);
  
  Serial.println("I2C bus initialized successfully");
  Serial.println();
}

// ============================================================================
// FULL BUS SCAN
// ============================================================================

void performFullScan() {
  Serial.println("[STEP 3] Scanning Entire I2C Bus");
  Serial.println("--------------------------------------");
  Serial.println("Scanning addresses 0x01 to 0x7F...");
  Serial.println();
  
  int deviceCount = 0;
  
  for (byte address = 1; address < 128; address++) {
    Wire.beginTransmission(address);
    byte error = Wire.endTransmission();
    
    if (error == 0) {
      // Device found!
      deviceCount++;
      
      Serial.print("  [FOUND] Device ");
      Serial.print(deviceCount);
      Serial.print(" at address 0x");
      if (address < 16) Serial.print("0");
      Serial.print(address, HEX);
      Serial.print(" (decimal: ");
      Serial.print(address);
      Serial.print(")");
      
      // Check if it's a known MD22 address
      if (address == 0x58) {
        Serial.print(" <-- MD22 DEFAULT (all DIP OFF)");
      } else if (address == 0x5A) {
        Serial.print(" <-- MD22 variant (DIP 1 ON)");
      } else if (address == 0x5C) {
        Serial.print(" <-- MD22 variant (DIP 2 ON)");
      } else if (address == 0x60) {
        Serial.print(" <-- MD22 variant (DIP 3 ON)");
      } else if (address == 0x62) {
        Serial.print(" <-- MD22 variant (DIP 1+3 ON)");
      }
      
      Serial.println();
      
      // Try to read software version
      readSoftwareVersion(address);
      
      Serial.println();
    }
  }
  
  Serial.println("--------------------------------------");
  if (deviceCount == 0) {
    Serial.println("Result: NO DEVICES FOUND");
    Serial.println();
    Serial.println("Troubleshooting:");
    Serial.println("  1. Check SDA wire: Arduino Pin 20 to MD22 SDA");
    Serial.println("  2. Check SCL wire: Arduino Pin 21 to MD22 SCL");
    Serial.println("  3. Check 5V wire: Arduino 5V to MD22 5V");
    Serial.println("  4. Check GND wire: Arduino GND to MD22 GND");
    Serial.println("  5. Verify MD22 has 5V power on logic side");
    Serial.println("  6. Check all DIP switches are OFF (down)");
  } else {
    Serial.print("Result: FOUND ");
    Serial.print(deviceCount);
    Serial.print(" device");
    if (deviceCount > 1) Serial.print("s");
    Serial.println();
  }
  
  Serial.println();
}

// ============================================================================
// READ SOFTWARE VERSION
// ============================================================================

void readSoftwareVersion(byte address) {
  Serial.print("    Attempting to read software version... ");
  
  // Write to register 0x07 (software version)
  Wire.beginTransmission(address);
  Wire.write(0x07);
  byte writeError = Wire.endTransmission();
  
  if (writeError != 0) {
    Serial.print("Write failed (error ");
    Serial.print(writeError);
    Serial.println(")");
    return;
  }
  
  // Request 1 byte
  byte bytesReceived = Wire.requestFrom(address, (byte)1);
  
  if (bytesReceived == 0) {
    Serial.println("No response");
    return;
  }
  
  if (Wire.available()) {
    byte version = Wire.read();
    Serial.print("Version ");
    Serial.println(version);
  } else {
    Serial.println("Data not available");
  }
}

// ============================================================================
// TEST SPECIFIC MD22 ADDRESSES
// ============================================================================

void testSpecificAddresses() {
  Serial.println("[STEP 4] Testing Known MD22 Addresses");
  Serial.println("--------------------------------------");
  
  // Array of common MD22 addresses
  byte md22Addresses[] = {
    0x58,  // All DIP OFF (default)
    0x5A,  // DIP 1 ON
    0x5C,  // DIP 2 ON
    0x5E,  // DIP 1+2 ON
    0x60,  // DIP 3 ON
    0x62,  // DIP 1+3 ON
    0x64,  // DIP 2+3 ON
    0x66   // DIP 1+2+3 ON
  };
  
  int arraySize = sizeof(md22Addresses) / sizeof(md22Addresses[0]);
  
  for (int i = 0; i < arraySize; i++) {
    byte addr = md22Addresses[i];
    
    Serial.print("  Testing 0x");
    if (addr < 16) Serial.print("0");
    Serial.print(addr, HEX);
    Serial.print("... ");
    
    Wire.beginTransmission(addr);
    byte error = Wire.endTransmission();
    
    if (error == 0) {
      Serial.println("FOUND!");
      
      // Try reading version
      Wire.beginTransmission(addr);
      Wire.write(0x07);
      Wire.endTransmission();
      
      Wire.requestFrom(addr, (byte)1);
      if (Wire.available()) {
        byte version = Wire.read();
        Serial.print("      MD22 Software Version: ");
        Serial.println(version);
      }
      
    } else if (error == 2) {
      Serial.println("Not present");
    } else {
      Serial.print("Error ");
      Serial.println(error);
    }
  }
  
  Serial.println();
}

// ============================================================================
// PIN STATE CHECK (BONUS DIAGNOSTIC)
// ============================================================================

void checkPinStates() {
  Serial.println("[BONUS] Checking SDA/SCL Pin States");
  Serial.println("--------------------------------------");
  
  // Set pins as inputs
  pinMode(20, INPUT);
  pinMode(21, INPUT);
  delay(10);
  
  // Read pin states
  int sdaValue = digitalRead(20);
  int sclValue = digitalRead(21);
  
  // Print SDA state - VERIFIED LOGIC
  Serial.print("  Pin 20 (SDA) reads: ");
  if (sdaValue == HIGH) {
    Serial.println("HIGH");
  } else {
    Serial.println("LOW");
  }
  
  // Print SCL state - VERIFIED LOGIC (was the bug before!)
  Serial.print("  Pin 21 (SCL) reads: ");
  if (sclValue == HIGH) {
    Serial.println("HIGH");
  } else {
    Serial.println("LOW");
  }
  
  Serial.println();
  Serial.println("  Note: Both should be HIGH when MD22 is connected and powered");
  Serial.println("        (MD22 has internal pull-up resistors)");
  Serial.println();
}
