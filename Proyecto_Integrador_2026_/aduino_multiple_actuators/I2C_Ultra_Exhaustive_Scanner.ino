/*
 * ULTRA-EXHAUSTIVE I2C SCANNER
 * 
 * This scanner tests EVERY possible I2C address from 0x00 to 0x7F (0-127)
 * using multiple detection methods to ensure nothing is missed.
 * 
 * SETUP:
 * - Arduino Mega via USB
 * - MD22 logic power connected (SDA, SCL, 5V, GND)
 * - Open Serial Monitor at 115200 baud
 * 
 * This will take about 30-40 seconds to complete.
 */

#include <Wire.h>

// Counters
int devicesFound = 0;
int addressesTested = 0;

void setup() {
  Serial.begin(115200);
  while (!Serial);
  delay(2000);  // Give time to open Serial Monitor
  
  Serial.println();
  Serial.println("=====================================");
  Serial.println("  ULTRA-EXHAUSTIVE I2C SCANNER");
  Serial.println("=====================================");
  Serial.println();
  Serial.println("This will test ALL 128 possible I2C addresses");
  Serial.println("using multiple detection methods.");
  Serial.println();
  Serial.println("Please wait... this takes 30-40 seconds");
  Serial.println();
  Serial.println("=====================================");
  Serial.println();
  
  // Initialize I2C
  Wire.begin();
  delay(500);
  
  Serial.println("Starting comprehensive scan...");
  Serial.println();
  
  // Scan EVERY address from 0x00 to 0x7F
  for (byte address = 0; address < 128; address++) {
    addressesTested++;
    
    // Print progress every 16 addresses
    if (address % 16 == 0) {
      Serial.print("Scanning 0x");
      if (address < 16) Serial.print("0");
      Serial.print(address, HEX);
      Serial.print(" to 0x");
      byte endAddr = address + 15;
      if (endAddr > 127) endAddr = 127;
      if (endAddr < 16) Serial.print("0");
      Serial.print(endAddr, HEX);
      Serial.println("...");
    }
    
    // METHOD 1: Standard beginTransmission/endTransmission
    Wire.beginTransmission(address);
    byte error1 = Wire.endTransmission();
    
    // Small delay between attempts
    delay(5);
    
    // METHOD 2: Try again with stop flag
    Wire.beginTransmission(address);
    byte error2 = Wire.endTransmission(true);
    
    // Small delay
    delay(5);
    
    // METHOD 3: Try requestFrom
    byte received = Wire.requestFrom(address, (byte)1, (byte)true);
    byte error3 = (received > 0) ? 0 : 4;
    
    // Small delay
    delay(5);
    
    // Check if ANY method found the device
    if (error1 == 0 || error2 == 0 || error3 == 0) {
      devicesFound++;
      
      Serial.println();
      Serial.println("***************************************");
      Serial.print("*** DEVICE FOUND at address 0x");
      if (address < 16) Serial.print("0");
      Serial.print(address, HEX);
      Serial.print(" (decimal ");
      Serial.print(address);
      Serial.println(")");
      Serial.println("***************************************");
      
      // Show which methods detected it
      Serial.print("  Detection methods: ");
      if (error1 == 0) Serial.print("[Method1:YES] ");
      if (error2 == 0) Serial.print("[Method2:YES] ");
      if (error3 == 0) Serial.print("[Method3:YES] ");
      Serial.println();
      
      // Check if it's a known MD22 address
      if (address == 0x58) {
        Serial.println("  >>> THIS IS MD22 DEFAULT ADDRESS! <<<");
        Serial.println("  >>> (All DIP switches OFF)");
      } else if (address == 0x5A) {
        Serial.println("  >>> MD22 with DIP switch 1 ON");
      } else if (address == 0x5C) {
        Serial.println("  >>> MD22 with DIP switch 2 ON");
      } else if (address == 0x60) {
        Serial.println("  >>> MD22 with DIP switch 3 ON");
      } else if (address == 0x62) {
        Serial.println("  >>> MD22 with DIP switches 1+3 ON");
      } else if (address >= 0x50 && address <= 0x6F) {
        Serial.println("  >>> Possibly MD22 or similar device");
      }
      
      // Try to read data from it
      Serial.println();
      Serial.println("  Attempting to communicate...");
      testCommunication(address);
      
      Serial.println("***************************************");
      Serial.println();
    }
  }
  
  // Print final results
  Serial.println();
  Serial.println("=====================================");
  Serial.println("  SCAN COMPLETE");
  Serial.println("=====================================");
  Serial.println();
  Serial.print("Total addresses tested: ");
  Serial.println(addressesTested);
  Serial.print("Total devices found: ");
  Serial.println(devicesFound);
  Serial.println();
  
  if (devicesFound == 0) {
    Serial.println("*** NO DEVICES FOUND ***");
    Serial.println();
    Serial.println("This means:");
    Serial.println("  1. MD22 is not connected, OR");
    Serial.println("  2. MD22 has no power (check 5V), OR");
    Serial.println("  3. SDA/SCL wires are disconnected, OR");
    Serial.println("  4. MD22 I2C circuit is faulty");
    Serial.println();
    Serial.println("Troubleshooting checklist:");
    Serial.println("  [ ] MD22 SDA wire connected to Arduino Pin 20");
    Serial.println("  [ ] MD22 SCL wire connected to Arduino Pin 21");
    Serial.println("  [ ] MD22 5V connected to Arduino 5V");
    Serial.println("  [ ] MD22 GND connected to Arduino GND");
    Serial.println("  [ ] Measure 5V between MD22 5V and GND pins");
    Serial.println("  [ ] All MD22 DIP switches in OFF position");
  } else {
    Serial.println("*** DEVICES DETECTED ***");
    Serial.println();
    if (devicesFound == 1) {
      Serial.println("Found exactly 1 device - likely your MD22!");
    } else {
      Serial.print("Found ");
      Serial.print(devicesFound);
      Serial.println(" devices - check which are MD22");
    }
  }
  
  Serial.println();
  Serial.println("=====================================");
  Serial.println();
  Serial.println("IMPORTANT: Send me ALL the output above!");
  Serial.println();
}

void loop() {
  // Nothing - scan runs once
}

// Test communication with found device
void testCommunication(byte address) {
  // Try to read register 0x07 (software version for MD22)
  Serial.print("    Reading register 0x07... ");
  Wire.beginTransmission(address);
  Wire.write(0x07);
  byte error = Wire.endTransmission();
  
  if (error != 0) {
    Serial.print("Write failed (error ");
    Serial.print(error);
    Serial.println(")");
  } else {
    // Try to read response
    delay(10);
    byte count = Wire.requestFrom(address, (byte)1);
    if (count > 0 && Wire.available()) {
      byte value = Wire.read();
      Serial.print("Success! Value: ");
      Serial.print(value);
      if (value > 0 && value < 20) {
        Serial.print(" (Likely MD22 software version)");
      }
      Serial.println();
    } else {
      Serial.println("No response");
    }
  }
  
  // Try to read register 0x00 (motor 1 speed for MD22)
  Serial.print("    Reading register 0x00... ");
  Wire.beginTransmission(address);
  Wire.write(0x00);
  error = Wire.endTransmission();
  
  if (error != 0) {
    Serial.print("Write failed (error ");
    Serial.print(error);
    Serial.println(")");
  } else {
    delay(10);
    byte count = Wire.requestFrom(address, (byte)1);
    if (count > 0 && Wire.available()) {
      byte value = Wire.read();
      Serial.print("Success! Value: ");
      Serial.println(value);
    } else {
      Serial.println("No response");
    }
  }
  
  // Try to read multiple bytes
  Serial.print("    Reading 4 bytes starting at 0x00... ");
  Wire.beginTransmission(address);
  Wire.write(0x00);
  error = Wire.endTransmission();
  
  if (error != 0) {
    Serial.print("Write failed (error ");
    Serial.print(error);
    Serial.println(")");
  } else {
    delay(10);
    byte count = Wire.requestFrom(address, (byte)4);
    if (count > 0) {
      Serial.print("Received ");
      Serial.print(count);
      Serial.print(" bytes: ");
      while (Wire.available()) {
        byte b = Wire.read();
        Serial.print("0x");
        if (b < 16) Serial.print("0");
        Serial.print(b, HEX);
        Serial.print(" ");
      }
      Serial.println();
    } else {
      Serial.println("No response");
    }
  }
}
