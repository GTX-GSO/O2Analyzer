#include "ads_sensor.h"
#include "config.h"

#include <Adafruit_ADS1X15.h>
#include <Wire.h>

static Adafruit_ADS1115 ads;
static bool adsReady = false;
static uint8_t adsAddr = 0;

// Soft-I2C (OLED) and HW Wire (ADS) share pins — unlock bus then reclaim Wire.
void adsPrepareBus() {
  Wire.end();

  pinMode(PIN_I2C_SDA, INPUT_PULLUP);
  pinMode(PIN_I2C_SCL, INPUT_PULLUP);
  delayMicroseconds(50);

  // Clock out up to 9 bits if a slave is holding SDA low
  pinMode(PIN_I2C_SCL, OUTPUT);
  digitalWrite(PIN_I2C_SCL, HIGH);
  for (int i = 0; i < 9; ++i) {
    if (digitalRead(PIN_I2C_SDA)) {
      break;
    }
    digitalWrite(PIN_I2C_SCL, LOW);
    delayMicroseconds(5);
    digitalWrite(PIN_I2C_SCL, HIGH);
    delayMicroseconds(5);
  }

  // STOP: SDA rising while SCL high
  pinMode(PIN_I2C_SDA, OUTPUT);
  digitalWrite(PIN_I2C_SDA, LOW);
  delayMicroseconds(5);
  digitalWrite(PIN_I2C_SCL, HIGH);
  delayMicroseconds(5);
  pinMode(PIN_I2C_SDA, INPUT_PULLUP);
  delayMicroseconds(20);

  Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);
  Wire.setClock(100000);
  Wire.setTimeOut(50);
}

int adsI2cProbe(uint8_t *outAddrs, int cap) {
  adsPrepareBus();
  static const uint8_t kProbe[] = {0x3C, 0x3D, 0x48, 0x49, 0x4A, 0x4B};
  int found = 0;
  for (unsigned i = 0; i < sizeof(kProbe) && found < cap; ++i) {
    const uint8_t addr = kProbe[i];
    Wire.beginTransmission(addr);
    if (Wire.endTransmission() == 0) {
      outAddrs[found++] = addr;
    }
  }
  return found;
}

void adsI2cScanLog() {
  uint8_t addrs[8];
  const int n = adsI2cProbe(addrs, 8);
  Serial.print(F("I2C probe SDA="));
  Serial.print(PIN_I2C_SDA);
  Serial.print(F(" SCL="));
  Serial.print(PIN_I2C_SCL);
  Serial.print(':');
  if (n == 0) {
    Serial.print(F(" (none)"));
  } else {
    for (int i = 0; i < n; ++i) {
      Serial.print(F(" 0x"));
      if (addrs[i] < 16) {
        Serial.print('0');
      }
      Serial.print(addrs[i], HEX);
    }
  }
  Serial.println();
  Serial.flush();
}

bool adsBegin() {
  adsPrepareBus();
  adsI2cScanLog();

  adsReady = false;
  adsAddr = 0;

  for (uint8_t addr = 0x48; addr <= 0x4B; ++addr) {
    if (ads.begin(addr, &Wire)) {
      adsReady = true;
      adsAddr = addr;
      break;
    }
  }

  if (!adsReady) {
    Serial.println(F("ADS: no ACK on 0x48-0x4B"));
    return false;
  }

  Serial.print(F("ADS OK addr=0x"));
  Serial.println(adsAddr, HEX);

  ads.setGain(GAIN_SIXTEEN);
  ads.setDataRate(RATE_ADS1115_128SPS);
  return true;
}

bool adsIsReady() { return adsReady; }

uint8_t adsGetAddress() { return adsAddr; }

bool adsReadMillivolts(float &mvOut) {
  if (!adsReady) {
    return false;
  }

  // Conversion ~8 ms at 128 SPS; Wire timeout aborts stuck ACLK
  const int16_t raw = ads.readADC_Differential_0_1();
  mvOut = ads.computeVolts(raw) * 1000.0f;
  return true;
}
