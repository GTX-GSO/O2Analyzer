#include "calib.h"
#include "config.h"

#include <Preferences.h>

static Preferences prefs;
static bool valid = false;
static float vAirMv = 0.0f;

bool calibBegin() {
  if (!prefs.begin(NVS_NAMESPACE, false)) {
    valid = false;
    vAirMv = 0.0f;
    return false;
  }

  valid = prefs.getBool(NVS_KEY_VALID, false);
  vAirMv = prefs.getFloat(NVS_KEY_V_AIR, 0.0f);

  if (!valid || vAirMv < CAL_MIN_MV || vAirMv > CAL_MAX_MV) {
    valid = false;
    vAirMv = 0.0f;
  }

  return true;
}

bool calibIsValid() { return valid; }

float calibGetVAirMv() { return vAirMv; }

bool calibAirCalibrate(float avgMv) {
  if (avgMv < CAL_MIN_MV || avgMv > CAL_MAX_MV) {
    return false;
  }

  vAirMv = avgMv;
  valid = true;
  prefs.putFloat(NVS_KEY_V_AIR, vAirMv);
  prefs.putBool(NVS_KEY_VALID, true);
  return true;
}

void calibInvalidate() {
  valid = false;
  vAirMv = 0.0f;
  prefs.putBool(NVS_KEY_VALID, false);
}
