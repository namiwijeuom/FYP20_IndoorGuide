#ifndef APP_TIMER_UTIL_H
#define APP_TIMER_UTIL_H

#include <stdbool.h>
#include <stdint.h>
#include "app_timer.h"

void app_timer_util_init(void);

void start_app_timer(uint32_t ms);

void restart_timer(uint32_t ms);

void is_timer_expired(bool *timer_state);

void reset_timer_flag(void);

#endif // APP_TIMER_UTIL_H
