#include "ads_sensor.h"
#include "calib.h"
#include "config.h"
#include "display.h"

#include <Arduino.h>
#include <cstdio>

static float filterBuf[FILTER_SIZE];
static int filterIndex = 0;
static int filterCount = 0;

static unsigned long lastSampleMs = 0;
static unsigned long lastPrintMs = 0;
static unsigned long lastAdsRetryMs = 0;

static void filterReset() {
  filterIndex = 0;
  filterCount = 0;
  for (int i = 0; i < FILTER_SIZE; ++i) {
    filterBuf[i] = 0.0f;
  }
}

static void filterPush(float v) {
  filterBuf[filterIndex] = v;
  filterIndex = (filterIndex + 1) % FILTER_SIZE;
  if (filterCount < FILTER_SIZE) {
    ++filterCount;
  }
}

static float filterAverage() {
  if (filterCount == 0) {
    return 0.0f;
  }
  float sum = 0.0f;
  for (int i = 0; i < filterCount; ++i) {
    sum += filterBuf[i];
  }
  return sum / static_cast<float>(filterCount);
}

// Boot auto air-cal with on-screen countdown 5..1
static bool runAutoAirCal() {
  Serial.println(F("CAL_START"));

  float sum = 0.0f;
  int n = 0;

  for (int sec = CAL_COUNTDOWN_SEC; sec >= 1; --sec) {
    char line2[20];
    snprintf(line2, sizeof(line2), "请稍后...%d", sec);
    displayShowStatus("空气标定中", line2);
    Serial.print(F("CAL_COUNT "));
    Serial.println(sec);
    Serial.flush();

    // OLED soft-I2C just ran — reclaim bus, then sample for ~1 s
    adsPrepareBus();
    const unsigned long t0 = millis();
    int readsThisSec = 0;
    while (millis() - t0 < 1000UL) {
      float mv = 0.0f;
      if (adsReadMillivolts(mv)) {
        sum += fabsf(mv);
        ++n;
        ++readsThisSec;
      }
      delay(CAL_SAMPLE_INTERVAL_MS);
    }
    Serial.print(F("CAL_SAMPLES "));
    Serial.println(readsThisSec);
    Serial.flush();
  }

  if (n == 0) {
    Serial.println(F("CAL_FAIL"));
    displayShowStatus("标定失败", "读数错");
    delay(2000);
    return false;
  }

  const float avgMv = sum / static_cast<float>(n);
  if (calibAirCalibrate(avgMv)) {
    Serial.print(F("CAL_OK v_air_mV="));
    Serial.println(avgMv, 3);
    return true;
  }

  Serial.print(F("CAL_FAIL v_mV="));
  Serial.println(avgMv, 3);
  char line2[12];
  snprintf(line2, sizeof(line2), "%.1fmV", static_cast<double>(avgMv));
  displayShowStatus("标定失败", line2);
  delay(2000);
  return false;
}

static void afterAdsReady() {
  // Every power-on: auto air calibration, then live O2 page
  while (!runAutoAirCal()) {
    // Retry until air voltage is in range (sensor in air)
  }
  filterReset();
  displayShowO2(-1.0f, 0.0f);
}

void setup() {
  pinMode(8, OUTPUT);
  digitalWrite(8, LOW);

  Serial.begin(115200);
  delay(800);
  Serial.println();
  Serial.println(F("O2Analyzer boot"));
  Serial.flush();

  calibBegin();
  displayBegin();
  if (displayIsReady()) {
    Serial.println(F("OLED_OK"));
    digitalWrite(8, HIGH);
  } else {
    Serial.println(F("OLED_FAIL"));
  }
  Serial.flush();

  if (adsBegin()) {
    Serial.println(F("ADS_OK"));
    afterAdsReady();
  } else {
    Serial.println(F("ADS_FAIL"));
    displayShowAdsFail();
  }
  Serial.flush();

  lastSampleMs = millis();
  lastPrintMs = millis();
  lastAdsRetryMs = millis();
}

void loop() {
  const unsigned long now = millis();

  if (!adsIsReady()) {
    if (now - lastAdsRetryMs >= 2000) {
      lastAdsRetryMs = now;
      uint8_t addrs[8];
      const int n = adsI2cProbe(addrs, 8);
      displayShowI2cProbe(addrs, n);
      delay(800);
      if (adsBegin()) {
        Serial.println(F("ADS_OK"));
        afterAdsReady();
      } else {
        Serial.println(F("ADS_FAIL"));
        displayShowAdsFail();
      }
    }
    return;
  }

  if (!calibIsValid()) {
    afterAdsReady();
    return;
  }

  if (now - lastSampleMs >= SAMPLE_INTERVAL_MS) {
    lastSampleMs = now;
    adsPrepareBus();
    float mv = 0.0f;
    if (adsReadMillivolts(mv)) {
      filterPush(fabsf(mv));
    }
  }

  if (now - lastPrintMs >= SERIAL_PRINT_INTERVAL_MS) {
    lastPrintMs = now;
    const float mv = filterAverage();
    const float o2 = (mv / calibGetVAirMv()) * AIR_O2_PERCENT;
    Serial.print(F("O2="));
    Serial.print(o2, 2);
    Serial.print(F("% mV="));
    Serial.println(mv, 3);
    displayShowO2(o2, mv);
  }
}
