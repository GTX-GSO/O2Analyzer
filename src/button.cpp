#include "button.h"
#include "config.h"

static bool lastRaw = HIGH;
static bool lastStableLevel = HIGH;
static bool pressed = false;
static unsigned long rawChangeMs = 0;
static unsigned long pressStartMs = 0;
static bool longPressFired = false;

void buttonBegin() {
  pinMode(PIN_BOOT_BTN, INPUT_PULLUP);
  lastRaw = digitalRead(PIN_BOOT_BTN);
  lastStableLevel = lastRaw;
  pressed = (lastStableLevel == LOW);
  rawChangeMs = millis();
  pressStartMs = 0;
  longPressFired = false;
}

bool buttonLongPressEdge() {
  const unsigned long now = millis();
  const bool raw = digitalRead(PIN_BOOT_BTN);

  if (raw != lastRaw) {
    lastRaw = raw;
    rawChangeMs = now;
  }

  if (raw != lastStableLevel && (now - rawChangeMs >= BTN_DEBOUNCE_MS)) {
    lastStableLevel = raw;
    if (lastStableLevel == LOW) {
      pressed = true;
      pressStartMs = now;
      longPressFired = false;
    } else {
      pressed = false;
      pressStartMs = 0;
      longPressFired = false;
    }
  }

  if (pressed && !longPressFired && (now - pressStartMs >= LONG_PRESS_MS)) {
    longPressFired = true;
    return true;
  }

  return false;
}
