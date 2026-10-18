#pragma once

#include <Arduino.h>

void buttonBegin();
// Call every loop. Returns true once when a long-press is completed (edge).
bool buttonLongPressEdge();
