#pragma once

#include <Arduino.h>

void displayBegin();
bool displayIsReady();

void displayShowAdsFail();
void displayShowI2cProbe(const uint8_t *addrs, int count);
void displayShowNeedCal(float mv);
void displayShowO2(float o2Percent, float mv);
void displayShowStatus(const char *line1, const char *line2 = nullptr);
