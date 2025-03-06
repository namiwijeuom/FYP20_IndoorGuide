#ifndef RTC_TIMER_H
#define RTC_TIMER_H


#include <stdint.h>
#include <stdbool.h>

void timer_init(const int time_step_value);

void start_timer(void);

void stop_timer(void);

void is_timer_expired(bool *state);





#endif // RTC_TIMER_H
