#pragma once

#include <Arduino.h>

void adsPrepareBus();
int adsI2cProbe(uint8_t *outAddrs, int cap);
void adsI2cScanLog();
bool adsBegin();
bool adsIsReady();
uint8_t adsGetAddress();
// Differential AIN0 - AIN1, PGA ±256 mV. Call adsPrepareBus() after OLED updates.
bool adsReadMillivolts(float &mvOut);
