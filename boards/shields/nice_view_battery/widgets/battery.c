#include <zephyr/kernel.h>
#include "battery.h"
#include "../assets/font.h"

LV_IMG_DECLARE(bolt);
LV_IMG_DECLARE(battery);
LV_IMG_DECLARE(battery_mask);

static void draw_single_battery(lv_obj_t *canvas, uint8_t level, bool charging, int offset_y) {
    lv_draw_img_dsc_t img_dsc;
    lv_draw_img_dsc_init(&img_dsc);
    lv_draw_rect_dsc_t rect_dsc;
    init_rect_dsc(&rect_dsc, LVGL_FOREGROUND);
    lv_draw_label_dsc_t outline_dsc;
    init_label_dsc(&outline_dsc, LVGL_BACKGROUND, &font, LV_TEXT_ALIGN_CENTER);
    lv_draw_label_dsc_t label_dsc;
    init_label_dsc(&label_dsc, LVGL_FOREGROUND, &font, LV_TEXT_ALIGN_CENTER);

    lv_canvas_draw_img(canvas, 0, offset_y, &battery, &img_dsc);
    lv_canvas_draw_rect(canvas, 4, offset_y + 4, 54 * level / 100, 23, &rect_dsc);
    lv_canvas_draw_img(canvas, 2, offset_y + 2, &battery_mask, &img_dsc);

    char text[10] = {};
    sprintf(text, "%i%%", level);

    const int y = offset_y + 9;
    const int w = 62;

    for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
            if (dx != 0 || dy != 0) {
                lv_canvas_draw_text(canvas, dx, y + dy, w, &outline_dsc, text);
            }
        }
    }

    lv_canvas_draw_text(canvas, 0, y, w, &label_dsc, text);

    if (charging) {
        lv_canvas_draw_img(canvas, 29, offset_y + 6, &bolt, &img_dsc);
    }
}

void draw_battery_status(lv_obj_t *canvas, const struct status_state *state) {
#if IS_ENABLED(CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_FETCHING)
    if (state->peripheral_battery_known) {
        draw_single_battery(canvas, state->battery, state->charging, 0);
        draw_single_battery(canvas, state->peripheral_battery, false, 35);
        return;
    }
#endif
    draw_single_battery(canvas, state->battery, state->charging, 0);
}
