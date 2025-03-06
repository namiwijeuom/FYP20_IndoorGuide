
//#include "rtc_timer.h"

//// RTC instance
//const nrf_drv_rtc_t rtc = NRF_DRV_RTC_INSTANCE(0);

//volatile bool timer_expired = false; // Flag to track timer expiration

//// RTC interrupt handler
//static void rtc_handler(nrf_drv_rtc_int_type_t int_type)
//{
//    if (int_type == NRF_DRV_RTC_INT_COMPARE0)
//    {
//        timer_expired = true;
//        printf("RTC Timer Expired\n");
//        nrf_drv_rtc_cc_disable(&rtc,0);

//        // Clear the event and restart the timer
//        //nrf_drv_rtc_cc_set(&rtc, 0, (TIME_STEP_MS * 32.768), true);
//    }
//}

//void rtc_timer_init()
//{
//    uint32_t err_code;

//    // Initialize RTC instance
//    nrf_drv_rtc_config_t config = NRF_DRV_RTC_DEFAULT_CONFIG;
//    err_code = nrf_drv_rtc_init(&rtc, &config, rtc_handler);
//    //APP_ERROR_CHECK(err_code);

//    // Enable the RTC instance
//    nrf_drv_rtc_enable(&rtc);
    
//}



//// Function to initialize and start the RTC timer
//void start_rtc_timer(uint32_t time_ms)
//{
//    uint32_t err_code;
//    // Set compare channel to trigger interrupt
//    err_code = nrf_drv_rtc_cc_set(&rtc, 0, (time_ms * 32.768), true);
//    //APP_ERROR_CHECK(err_code);
    
//}



//// Function to check if timer expired
//void is_rtc_timer_expired(bool *expired)
//{
//    *expired = timer_expired;
//    if (timer_expired) {
//        timer_expired = false; // Reset flag for next interval
//    }
//}


#include "rtc_timer.h"
#include "nrf.h"

//#define TIME_STEP_MS 1000  // Set timer duration (1s)
#define CPU_FREQ_MHZ 64    // CPU clock frequency in MHz

static uint32_t start_time = 0;
static volatile bool timer_expired = false;

static  int time_step;

void timer_init(const int time_step_value)
{
    time_step = time_step_value;
    // Enable DWT for cycle counting
    CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;
    DWT->CYCCNT = 0;
    DWT->CTRL |= DWT_CTRL_CYCCNTENA_Msk;
}


static uint32_t get_time_ms(void)
{
    return (DWT->CYCCNT) / (CPU_FREQ_MHZ * 1000); // Convert cycles to ms
}



void start_timer(void)
{
    timer_expired = false;
    start_time = get_time_ms();
}

void stop_timer(void)
{
    timer_expired = false;
}


void is_timer_expired(bool *state)
{
    if ((get_time_ms() - start_time) >= time_step)
    {
        timer_expired = true;
    }

    *state = timer_expired;

}
