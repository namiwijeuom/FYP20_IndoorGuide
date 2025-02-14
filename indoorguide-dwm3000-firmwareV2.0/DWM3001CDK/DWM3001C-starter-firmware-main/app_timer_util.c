#include "app_timer_util.h"

APP_TIMER_DEF(my_timer);
static volatile bool timer_expired = false;

// Timer callback function
static void timer_handler(void *p_context)
{
    timer_expired = true;
}

// Initialize app_timer (must be called once in main)
void app_timer_util_init(void)
{
    app_timer_init();
    app_timer_create(&my_timer, APP_TIMER_MODE_SINGLE_SHOT, timer_handler);
}

// Start the timer
void start_app_timer(uint32_t ms)
{
    timer_expired = false;
    app_timer_start(my_timer, APP_TIMER_TICKS(ms), NULL);
}


// Restart the timer (avoids multiple allocations)
void restart_timer(uint32_t ms)
{
    app_timer_stop(my_timer);
    app_timer_start(my_timer, APP_TIMER_TICKS(ms), NULL);
}



// Check if timer has expired
void is_timer_expired(bool *timer_expired_state)
{
    if(timer_expired)
    {
      *timer_expired_state = true;
    }
    else
    {
      *timer_expired_state = false;
    }    
}

// Reset timer flag manually if needed
void reset_timer_flag(void)
{
    timer_expired = false;
}


