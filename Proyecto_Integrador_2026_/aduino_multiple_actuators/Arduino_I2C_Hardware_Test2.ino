/*
 * Arduino Mega I2C Pin Test
 * 
 * This tests if the I2C pins (20/21) on Arduino Mega are working
 * 
 * Step 1: Upload this code
 * Step 2: Disconnect MD22 completely (all wires from MD22)
 * Step 3: Connect a 4.7k resistor between Pin 20 and 5V
 * Step 4: Connect a 4.7k resistor between Pin 21 and 5V
 *         (These are pull-up resistors - use any resistor 2k-10k if you have)
 * Step 5: Open Serial Monitor at 115200 baud
 * 
 * If you don't have resistors, just run it anyway and tell me the output
 */

#include <Wire.h>

void setup() {
  Serial.begin(115200);
  while (!Serial);
  
  delay(1000);
  
  Serial.println("\n=== Arduino Mega I2C Hardware Test ===");
  Serial.println();
  
  // Check which board we're on
  #if defined(__AVR_ATmega2560__)
    Serial.println("Board: Arduino Mega 2560 - CORRECT!");
    Serial.println("I2C Pins: SDA=Pin20, SCL=Pin21");
  #elif defined(__AVR_ATmega328P__)
    Serial.println("Board: Arduino Uno/Nano");
    Serial.println("ERROR: I2C Pins should be SDA=A4, SCL=A5");
    Serial.println("But you said you're using Pin 20/21...");
    Serial.println("This might be the problem!");
  #else
    Serial.println("Board: Unknown");
  #endif
  
  Serial.println();
  Serial.println("Initializing I2C...");
  
  Wire.begin();
  delay(100);
  
  Serial.println("I2C initialized");
  Serial.println();
  
  // Test 1: Try to scan
  Serial.println("Test 1: Scanning I2C bus");
  scanBus();
  
  Serial.println();
  
  // Test 2: Pin state check
  Serial.println("Test 2: Checking SDA/SCL pin states");
  checkPinStates();
  
  Serial.println();
  Serial.println("=== Test Complete ===");
  Serial.println();
  Serial.println("IMPORTANT: Tell me ALL the output above!");
}

void loop() {
  // Nothing
}

void scanBus() {
  int found = 0;
  
  for (byte addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    byte error = Wire.endTransmission();
    
    if (error == 0) {
      Serial.print("  Device at 0x");
      if (addr < 16) Serial.print("0");
      Serial.println(addr, HEX);
      found++;
    }
  }
  
  if (found == 0) {
    Serial.println("  No devices found");
    Serial.println("  (This is expected if MD22 is disconnected)");
  } else {
    Serial.print("  Found ");
    Serial.print(found);
    Serial.println(" device(s)");
  }
}

void checkPinStates() {
  // On Mega, SDA=20, SCL=21
  // Let's see if we can read them
  
  pinMode(20, INPUT);
  pinMode(21, INPUT);
  
  delay(10);
  
  int sdaState = digitalRead(20);
  int sclState = digitalRead(21);
  
  Serial.print("  Pin 20 (SDA) reads: ");
  Serial.println(sdaState == HIGH ? "HIGH" : "LOW");
  
  Serial.print("  Pin 21 (SCL) reads: ");
  Serial.println(sclState == HIGH ? "HIGH" : "LOW");
  
  Serial.println();
  Serial.println("  Note: Both should be HIGH if pull-up resistors present");
  Serial.println("        Both LOW if no pull-ups (might be OK, MD22 has internal pull-ups)");
}
