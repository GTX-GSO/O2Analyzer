#pragma once

#include <Arduino.h>

// I2C: board OLED is hardwired to GPIO5 (SDA) / GPIO6 (SCL).
// ADS1115 shares this bus (avoid GPIO8 LED / GPIO9 BOOT).
static const int PIN_I2C_SDA = 5;
static const int PIN_I2C_SCL = 6;

// BOOT button (unused for calibration; kept for board pin map)
static const int PIN_BOOT_BTN = 9;
static const unsigned long LONG_PRESS_MS = 2500;
static const unsigned long BTN_DEBOUNCE_MS = 30;

// ADS1115
static const uint8_t ADS1115_I2C_ADDR = 0x48;
static const uint32_t I2C_CLOCK_HZ = 400000;

// Onboard 0.42" OLED — EastRising SSD1306 72×40 @ 0x3C (U8G2_SSD1306_72X40_ER)
static const uint8_t OLED_I2C_ADDR = 0x3C;

// Sampling / filter
static const int FILTER_SIZE = 8;
static const unsigned long SAMPLE_INTERVAL_MS = 50;
static const unsigned long SERIAL_PRINT_INTERVAL_MS = 500;

// Air calibration (auto on every boot, 5s countdown)
static const float AIR_O2_PERCENT = 20.9f;
static const float CAL_MIN_MV = 8.0f;
static const float CAL_MAX_MV = 15.0f;
static const int CAL_COUNTDOWN_SEC = 5;
static const unsigned long CAL_SAMPLE_INTERVAL_MS = 50;

// NVS
static const char *NVS_NAMESPACE = "o2cal";
static const char *NVS_KEY_V_AIR = "v_air";
static const char *NVS_KEY_VALID = "valid";
