#include "rtc_timer.h"
#include "nrf_drv_rtc.h"
#include "nrf_log.h"

const nrf_drv_rtc_t rtc_instance = NRF_DRV_RTC_INSTANCE(2); // Use RTC2

static volatile bool timer_expired = false;

// RTC Interrupt Handler
static void rtc_handler(nrf_drv_rtc_int_type_t int_type)
{
    if (int_type == NRF_DRV_RTC_INT_COMPARE0)
    {
        timer_expired = true;
        nrf_drv_rtc_counter_clear(&rtc_instance);
        nrf_drv_rtc_cc_disable(&rtc_instance, 0);  // Disable after triggering
    }
}

// Initialize RTC Timer
void rtc_timer_init(void)
{
    nrf_drv_rtc_config_t config = NRF_DRV_RTC_DEFAULT_CONFIG;
    config.prescaler = 32;  // 1 tick = 1 ms

    ret_code_t err_code = nrf_drv_rtc_init(&rtc_instance, &config, rtc_handler);
    //APP_ERROR_CHECK(err_code);

    nrf_drv_rtc_enable(&rtc_instance);
}

// Start RTC Timer
void start_rtc_timer(uint32_t ms)
{
    timer_expired = false;
    
    ret_code_t err_code = nrf_drv_rtc_cc_set(&rtc_instance, 0, ms, true);
    //APP_ERROR_CHECK(err_code);
}

// Check if Timer Expired
void is_rtc_timer_expired(bool *timer_expired_state)
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

// Reset Timer Expired Flag
void reset_rtc_timer_flag(void)
{
    timer_expired = false;
}
