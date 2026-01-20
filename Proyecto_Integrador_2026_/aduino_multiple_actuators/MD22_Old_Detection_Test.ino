/*
 * OLD MD22 Detection Test (Pre-2010 Models)
 * 
 * For MD22 purchased before 2010 (like your 2008 model)
 * Uses base address 0xB0 instead of 0x58
 * 
 * DIP switches should be: ALL OFF for address 0xB0
 */

#include <Wire.h>

// OLD MD22 uses 0xB0 base address (7-bit: 0x58 with R/W bit handled separately)
const byte MD22_OLD_BASE = 0x58;  // This is the 7-bit address Arduino Wire library uses

void setup() {
  Serial.begin(115200);
  while (!Serial);
  
  delay(1000);
  
  Serial.println("\n=== OLD MD22 (2008) Detection Test ===");
  Serial.println("For MD22 purchased before 2010");
  Serial.println("DIP Switches: ALL OFF expected");
  Serial.println();
  
  Wire.begin();
  delay(100);
  
  // Test 1: Full I2C scan
  Serial.println("Test 1: Full I2C Bus Scan");
  Serial.println("Scanning ALL addresses (0x01 to 0x7F)...");
  fullScan();
  
  Serial.println();
  
  // Test 2: Try common OLD MD22 addresses
  Serial.println("Test 2: Testing Known OLD MD22 Addresses");
  testOldMD22Addresses();
  
  Serial.println();
  Serial.println("=== Test Complete ===");
  Serial.println();
  
  Serial.println("IMPORTANT: Tell me which addresses were found!");
  Serial.println("Press RESET to run test again");
}

void loop() {
  // Nothing
}

void fullScan() {
  byte error, address;
  int deviceCount = 0;
  
  for (address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();
    
    if (error == 0) {
      Serial.print("  >>> DEVICE FOUND at 0x");
      if (address < 16) Serial.print("0");
      Serial.print(address, HEX);
      Serial.print(" (decimal: ");
      Serial.print(address);
      Serial.print(")");
      
      // Check if it might be MD22
      if (address == 0x58) {
        Serial.print(" <- POSSIBLE OLD MD22 (7-bit address)");
      } else if (address >= 0x50 && address <= 0x5F) {
        Serial.print(" <- Could be MD22 variant");
      }
      
      Serial.println();
      deviceCount++;
      
      // Try to read from it
      tryReadDevice(address);
    }
  }
  
  Serial.println();
  if (deviceCount == 0) {
    Serial.println("  [ERROR] NO I2C DEVICES FOUND!");
    Serial.println();
    Serial.println("  This means WIRING ISSUE:");
    Serial.println("  - Arduino Mega: SDA=Pin20, SCL=Pin21");
    Serial.println("  - Check all GND connections");
    Serial.println("  - MD22 needs 5V on logic side");
    Serial.println("  - MD22 needs 12V on motor side");
    Serial.println("  - Try swapping SDA/SCL wires");
  } else {
    Serial.print("  Total devices found: ");
    Serial.println(deviceCount);
  }
}

void tryReadDevice(byte address) {
  // Try to read software version (register 0x07)
  Wire.beginTransmission(address);
  Wire.write(0x07);
  byte error = Wire.endTransmission();
  
  if (error == 0) {
    Wire.requestFrom(address, 1);
    if (Wire.available()) {
      byte version = Wire.read();
      Serial.print("      Software version: ");
      Serial.println(version);
    }
  }
}

void testOldMD22Addresses() {
  // Test common OLD MD22 addresses with different DIP settings
  byte addresses[] = {
    0x58,  // All OFF (most likely for your setup)
    0x59,  // DIP 1 ON
    0x5A,  // DIP 1 ON (alternative)
    0x5B,
    0x5C,  // DIP 2 ON
    0x5D,
    0x5E,
    0x5F,
    0x60   // DIP 3 ON
  };
  
  for (int i = 0; i < 9; i++) {
    byte addr = addresses[i];
    
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
      
      Wire.requestFrom(addr, 1);
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
}
