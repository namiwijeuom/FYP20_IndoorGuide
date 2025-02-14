#ifndef RTC_TIMER_H
#define RTC_TIMER_H

#include <stdbool.h>
#include <stdint.h>

// Initialize RTC timer (call once in main)
void rtc_timer_init(void);

// Start RTC timer with given milliseconds
void start_rtc_timer(uint32_t ms);

// Check if the timer has expired
void is_rtc_timer_expired(bool *timer_expired_state);

// Reset timer expired flag
void reset_rtc_timer_flag(void);

#endif // RTC_TIMER_H
