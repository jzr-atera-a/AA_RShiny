/*
 * Simple MD22 Detection Test
 * 
 * This will scan for MD22 and try to communicate with it
 * Tests address 0x58 (all DIP switches OFF)
 */

#include <Wire.h>

const byte MD22_DEFAULT_ADDRESS = 0x58;  // All DIP switches OFF

void setup() {
  Serial.begin(115200);
  while (!Serial);
  
  delay(1000);  // Wait for everything to stabilize
  
  Serial.println("\n=== MD22 Detection Test ===");
  Serial.println("DIP Switches should be: ALL OFF");
  Serial.println("Expected address: 0x58");
  Serial.println();
  
  // Initialize I2C
  Wire.begin();
  delay(100);
  
  // Test 1: Scan entire I2C bus
  Serial.println("Test 1: Scanning I2C bus...");
  scanI2C();
  
  Serial.println();
  
  // Test 2: Try to ping MD22 at 0x58
  Serial.println("Test 2: Attempting to communicate with MD22 at 0x58...");
  testMD22Address(MD22_DEFAULT_ADDRESS);
  
  Serial.println();
  Serial.println("=== Test Complete ===");
  Serial.println("Press RESET to run again");
}

void loop() {
  // Do nothing
}

void scanI2C() {
  byte error, address;
  int deviceCount = 0;
  
  for (address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();
    
    if (error == 0) {
      Serial.print("  [FOUND] Device at address 0x");
      if (address < 16) Serial.print("0");
      Serial.print(address, HEX);
      
      if (address == 0x58) {
        Serial.print(" <- MD22 (all DIP OFF)");
      } else if (address == 0x5A) {
        Serial.print(" <- MD22 (DIP 1 ON)");
      } else if (address == 0x5C) {
        Serial.print(" <- MD22 (DIP 2 ON)");
      } else if (address == 0x60) {
        Serial.print(" <- MD22 (DIP 3 ON)");
      } else if (address == 0x62) {
        Serial.print(" <- MD22 (DIP 1+3 ON)");
      }
      
      Serial.println();
      deviceCount++;
    }
  }
  
  if (deviceCount == 0) {
    Serial.println("  [ERROR] NO devices found!");
    Serial.println();
    Serial.println("  Troubleshooting:");
    Serial.println("  1. Check SDA connection (Arduino Pin 20 on Mega)");
    Serial.println("  2. Check SCL connection (Arduino Pin 21 on Mega)");
    Serial.println("  3. Check GND connection (common ground)");
    Serial.println("  4. Check MD22 has 5V power on logic side");
    Serial.println("  5. Check MD22 has 12V power on motor side");
    Serial.println("  6. Try swapping SDA and SCL wires");
  } else {
    Serial.print("  Total devices found: ");
    Serial.println(deviceCount);
  }
}

void testMD22Address(byte address) {
  Wire.beginTransmission(address);
  byte error = Wire.endTransmission();
  
  if (error == 0) {
    Serial.print("  [SUCCESS] MD22 responding at 0x");
    if (address < 16) Serial.print("0");
    Serial.println(address, HEX);
    
    // Try to read software version
    Serial.print("  Reading MD22 software version... ");
    Wire.beginTransmission(address);
    Wire.write(0x07);  // Software revision register
    Wire.endTransmission();
    
    Wire.requestFrom(address, 1);
    if (Wire.available()) {
      byte version = Wire.read();
      Serial.print("Version ");
      Serial.println(version);
      
      // Try to read voltage
      Serial.print("  Reading MD22 battery voltage... ");
      Wire.beginTransmission(address);
      Wire.write(0x0A);  // Battery volts register
      Wire.endTransmission();
      
      Wire.requestFrom(address, 1);
      if (Wire.available()) {
        byte voltage = Wire.read();
        float volts = voltage / 10.0;
        Serial.print(volts);
        Serial.println("V");
      } else {
        Serial.println("FAILED");
      }
      
      Serial.println();
      Serial.println("  [OK] MD22 is working correctly!");
      
    } else {
      Serial.println("FAILED");
      Serial.println("  [WARNING] MD22 found but not responding properly");
    }
    
  } else if (error == 2) {
    Serial.print("  [ERROR] No device at 0x");
    if (address < 16) Serial.print("0");
    Serial.println(address, HEX);
    Serial.println("  Check DIP switch settings!");
    
  } else {
    Serial.print("  [ERROR] I2C error ");
    Serial.print(error);
    Serial.print(" at address 0x");
    if (address < 16) Serial.print("0");
    Serial.println(address, HEX);
  }
}
