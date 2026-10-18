#include "display.h"
#include "config.h"

#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>
#include <cstdio>

// EastRising 0.42" 72×40 — native constructor maps the SSD1306 window;
// Soft I2C: HW Wire blanks this panel on many C3+0.42 boards.
static U8G2_SSD1306_72X40_ER_F_SW_I2C u8g2(U8G2_R0,
                                            /* clock=*/PIN_I2C_SCL,
                                            /* data=*/PIN_I2C_SDA,
                                            /* reset=*/U8X8_PIN_NONE);

static const int W = 72;
static const int H = 40;
static const int PAD = 1;
// Physical aperture clips ~1–2 px at the top edge on many C3+0.42 boards.
static const int TOP_MARGIN = 2;
static const int INNER_W = W - 2 * PAD;

static bool displayReady = false;

static const uint8_t *fitCnFont(const char *utf8) {
  static const uint8_t *const kFonts[] = {
      u8g2_font_wqy14_t_gb2312a,
      u8g2_font_wqy12_t_gb2312a,
  };
  for (unsigned i = 0; i < sizeof(kFonts) / sizeof(kFonts[0]); ++i) {
    u8g2.setFont(kFonts[i]);
    if (u8g2.getUTF8Width(utf8) <= INNER_W) {
      return kFonts[i];
    }
  }
  return u8g2_font_wqy12_t_gb2312a;
}

static int centerX(int tw) {
  int x = PAD + (INNER_W - tw) / 2;
  if (x < PAD) {
    x = PAD;
  }
  if (x + tw > W - PAD) {
    x = W - PAD - tw;
  }
  if (x < 0) {
    x = 0;
  }
  return x;
}

static void drawCenteredUtf8(const uint8_t *font, const char *utf8, int baseline) {
  if (!utf8) {
    return;
  }
  u8g2.setFont(font);
  u8g2.drawUTF8(centerX(u8g2.getUTF8Width(utf8)), baseline, utf8);
}

static void drawCenteredAscii(const uint8_t *font, const char *text, int baseline) {
  if (!text) {
    return;
  }
  u8g2.setFont(font);
  u8g2.drawStr(centerX(u8g2.getStrWidth(text)), baseline, text);
}

// Place glyph baseline so the font box sits fully inside [top, bottom].
static int baselineInBand(const uint8_t *font, int top, int bottom) {
  u8g2.setFont(font);
  const int ascent = u8g2.getAscent();
  const int descent = u8g2.getDescent(); // typically <= 0
  const int box = ascent - descent;
  const int band = bottom - top;
  if (box >= band) {
    return top + ascent;
  }
  return top + (band - box) / 2 + ascent;
}

static void flushHero(const char *title, const char *sub) {
  u8g2.clearBuffer();
  const uint8_t *titleFont = fitCnFont(title);
  if (sub && sub[0]) {
    drawCenteredUtf8(titleFont, title,
                     baselineInBand(titleFont, TOP_MARGIN, H / 2));
    drawCenteredUtf8(u8g2_font_wqy12_t_gb2312a, sub,
                     baselineInBand(u8g2_font_wqy12_t_gb2312a, H / 2, H));
  } else {
    drawCenteredUtf8(titleFont, title,
                     baselineInBand(titleFont, TOP_MARGIN, H));
  }
  u8g2.sendBuffer();
}

void displayBegin() {
  u8g2.setI2CAddress(OLED_I2C_ADDR << 1);
  displayReady = u8g2.begin();
  Serial.print(F("OLED begin="));
  Serial.println(displayReady ? 1 : 0);
  Serial.flush();
  if (!displayReady) {
    return;
  }

  u8g2.enableUTF8Print();
  u8g2.setFontMode(1);
  u8g2.setFontDirection(0);
  u8g2.setContrast(255);
  u8g2.setPowerSave(0);

  flushHero("猫猫测氧仪", "正在启动...");
}

bool displayIsReady() { return displayReady; }

void displayShowAdsFail() {
  if (!displayReady) {
    return;
  }
  flushHero("传感器", "未连接");
}

void displayShowI2cProbe(const uint8_t *addrs, int count) {
  if (!displayReady) {
    return;
  }
  char line[20];
  if (count <= 0) {
    flushHero("I2C无设备", "查5/6线");
    return;
  }
  if (count == 1) {
    snprintf(line, sizeof(line), "%02X", addrs[0]);
  } else {
    snprintf(line, sizeof(line), "%02X %02X", addrs[0], addrs[1]);
  }
  bool hasOled = false;
  bool hasAds = false;
  for (int i = 0; i < count; ++i) {
    if (addrs[i] == 0x3C || addrs[i] == 0x3D) {
      hasOled = true;
    }
    if (addrs[i] >= 0x48 && addrs[i] <= 0x4B) {
      hasAds = true;
    }
  }
  if (hasOled && !hasAds) {
    flushHero("仅有OLED", line);
  } else if (hasAds) {
    flushHero("发现ADS", line);
  } else {
    flushHero("I2C设备", line);
  }
}

void displayShowNeedCal(float mv) {
  if (!displayReady) {
    return;
  }
  char sub[12];
  snprintf(sub, sizeof(sub), "%.1fmV", static_cast<double>(mv));
  flushHero("需标定", sub);
}

void displayShowO2(float o2Percent, float mv) {
  if (!displayReady) {
    return;
  }
  (void)mv;

  char num[12];
  if (o2Percent < 0.0f || o2Percent > 999.0f) {
    snprintf(num, sizeof(num), "--.-%%");
  } else {
    snprintf(num, sizeof(num), "%.1f%%", static_cast<double>(o2Percent));
  }

  static const uint8_t *const kNumFonts[] = {
      u8g2_font_logisoso22_tr,
      u8g2_font_logisoso18_tr,
      u8g2_font_logisoso16_tr,
  };

  const uint8_t *titleFont = u8g2_font_wqy12_t_gb2312a;
  const int titleBand = TOP_MARGIN + 13;
  const uint8_t *numFont = kNumFonts[0];
  for (unsigned i = 0; i < sizeof(kNumFonts) / sizeof(kNumFonts[0]); ++i) {
    u8g2.setFont(kNumFonts[i]);
    if (u8g2.getStrWidth(num) <= INNER_W) {
      numFont = kNumFonts[i];
      break;
    }
    numFont = kNumFonts[i];
  }

  u8g2.clearBuffer();
  drawCenteredUtf8(titleFont, "氧气含量",
                   baselineInBand(titleFont, TOP_MARGIN, titleBand));
  drawCenteredAscii(numFont, num, baselineInBand(numFont, titleBand, H));
  u8g2.sendBuffer();
}

void displayShowStatus(const char *line1, const char *line2) {
  if (!displayReady) {
    return;
  }
  flushHero(line1, line2);
}
