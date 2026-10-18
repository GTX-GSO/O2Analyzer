#pragma once

#include <Arduino.h>

bool calibBegin();
bool calibIsValid();
float calibGetVAirMv();
// Average several samples; save only if within air window. Returns true on success.
bool calibAirCalibrate(float avgMv);
void calibInvalidate();
