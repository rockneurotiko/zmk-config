# Display Battery Tuning Guide

The `zmk-nice-oled` module adds WPM tracking, animations, and modifier
indicators to the nice!view display. These features keep the CPU awake more
often than the stock static display, which **reduces battery life**.

Below are the knobs you can turn — ordered from least to most aggressive.

---

## Level 1 — Lower animation frame rates (current defaults)

Already applied in `corne_choc_pro.conf`:

```conf
CONFIG_NICE_OLED_WIDGET_WPM_BONGO_CAT_ANIMATION_MS=500        # 2 fps (default 300)
CONFIG_NICE_OLED_WIDGET_HID_INDICATORS_BONGO_CAT_ANIMATION_MS=500
```

## Level 2 — Blank screen after idle timeout

```conf
CONFIG_ZMK_DISPLAY_BLANK_ON_IDLE=y          # blank when ZMK enters idle
```

The display turns off after `CONFIG_ZMK_IDLE_TIMEOUT` (default 30 s). It wakes
on the next keypress. This is the single biggest battery saver.

## Level 3 — Disable bongo cat, use number-only WPM

```conf
CONFIG_NICE_OLED_WIDGET_WPM_BONGO_CAT=n     # no animation at all
CONFIG_NICE_OLED_WIDGET_WPM_NUMBER=y         # still shows WPM as text
```

## Level 4 — Disable WPM entirely

```conf
CONFIG_NICE_OLED_WIDGET_WPM=n
CONFIG_ZMK_WPM=n                             # also disables the WPM tracker
```

## Level 5 — Disable modifiers / HID indicators

```conf
CONFIG_NICE_OLED_WIDGET_MODIFIERS_INDICATORS=n
CONFIG_NICE_OLED_WIDGET_HID_INDICATORS=n
```

## Level 6 — Disable Raw HID

Raw HID only works over USB anyway. If you never plug in:

```conf
CONFIG_NICE_OLED_WIDGET_RAW_HID=n
```

This saves flash and a small amount of RAM.

## Level 7 — Static display only (maximum battery)

Disable everything animated, keep just battery + layer + BT status:

```conf
CONFIG_NICE_OLED_WIDGET_WPM=n
CONFIG_ZMK_WPM=n
CONFIG_NICE_OLED_WIDGET_MODIFIERS_INDICATORS=n
CONFIG_NICE_OLED_WIDGET_HID_INDICATORS=n
CONFIG_NICE_OLED_WIDGET_RAW_HID=n
CONFIG_NICE_OLED_SHOW_SLEEP_ART_ON_IDLE=n
CONFIG_ZMK_DISPLAY_BLANK_ON_IDLE=y
```

## Level 8 — Nuclear: disable display entirely

If battery life is critical (e.g. travelling):

```conf
CONFIG_ZMK_DISPLAY=n
```

---

## Quick reference: animation speed configs

| Config | Default | Description |
|---|---|---|
| `CONFIG_NICE_OLED_WIDGET_WPM_BONGO_CAT_ANIMATION_MS` | 300 | Bongo cat frame delay |
| `CONFIG_NICE_OLED_WIDGET_WPM_LUNA_ANIMATION_MS` | 300 | Luna frame delay |
| `CONFIG_NICE_OLED_WIDGET_HID_INDICATORS_BONGO_CAT_ANIMATION_MS` | 300 | CapsLock bongo cat |
| `CONFIG_NICE_OLED_WIDGET_ANIMATION_PERIPHERAL_MS` | varies | Peripheral animation |

Higher values = slower animation = less CPU wake-ups = better battery.
