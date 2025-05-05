/*********************************************************************
*                    SEGGER Microcontroller GmbH                     *
*                        The Embedded Experts                        *
**********************************************************************
*                                                                    *
*            (c) 2014 - 2020 SEGGER Microcontroller GmbH             *
*                                                                    *
*           www.segger.com     Support: support@segger.com           *
*                                                                    *
**********************************************************************
*                                                                    *
* All rights reserved.                                               *
*                                                                    *
* Redistribution and use in source and binary forms, with or         *
* without modification, are permitted provided that the following    *
* conditions are met:                                                *
*                                                                    *
* - Redistributions of source code must retain the above copyright   *
*   notice, this list of conditions and the following disclaimer.    *
*                                                                    *
* - Neither the name of SEGGER Microcontroller GmbH                  *
*   nor the names of its contributors may be used to endorse or      *
*   promote products derived from this software without specific     *
*   prior written permission.                                        *
*                                                                    *
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND             *
* CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,        *
* INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF           *
* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE           *
* DISCLAIMED.                                                        *
* IN NO EVENT SHALL SEGGER Microcontroller GmbH BE LIABLE FOR        *
* ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR           *
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT  *
* OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;    *
* OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF      *
* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT          *
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE  *
* USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH   *
* DAMAGE.                                                            *
*                                                                    *
**********************************************************************

-------------------------- END-OF-HEADER -----------------------------

File    : main.c
Purpose : DWM3001C build main entry point for simple exmaples.

*/

#include <boards.h>
#include <deca_spi.h>
#include <port.h>
#include <sdk_config.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <stdint.h>
#include <stdbool.h>
#include "nrf_drv_clock.h"
#include "nrf_gpio.h"
#include "nrf_delay.h"
#include "nrf_log.h"
#include "nrf_log_ctrl.h"
#include "nrf_log_default_backends.h"

//#include "nrfx_systick.h"

#include "uart.h"

#include "Applications/Tag_app/tag_app.h"
#include "Applications/Anchor_app/anchor_app.h"



/*! ------------------------------------------------------------------------------------------------------------------
 * @fn test_run_info()
 *
 * @brief  This function is simply a printf() call for a string. It is implemented differently on other platforms,
 *         but on the DWM3001C, a printf() call is .
 *
 * @param data - Message data, this data should be NULL string.
 *
 * output parameters
 *
 * no return value
 */
void test_run_info(unsigned char *data) 
{
    /* Sending data over UART */
    uart_send_string(data);
    uint8_t newline[] = "\n\r";
    uart_send_string(newline);
}


//#define TAG_APP
#define ANCHOR_APP



int main(void)
{     
    /* Initializing system tick */
    nrfx_systick_init();
    /* Initialize all configured peripherals */
    bsp_board_init(BSP_INIT_LEDS | BSP_INIT_BUTTONS);

    /* Initialise DWM3001C GPIOs */
    gpio_init();

    /* Initialise the SPI for DWM3001C */
    dwm3001c_spi_init();

    /* Configuring interrupt*/
    dw_irq_init();


    /* Initializing UART */
    uart_init();

    /* Small pause before startup */
    nrf_delay_ms(2);



    // UNCOMMENT EXACTLY ONE OF THE BELOW EXAMPLES, AND ALSO UNCOMMENT THE CORRESPONDING #define IN example_selection.h:
    //extern int read_dev_id(void);
    //extern int simple_tx(void); //simple_tx();
    // extern int simple_tx_pdoa(void); simple_tx_pdoa();
    // extern int simple_rx(void); simple_rx();
    // extern int simple_rx_nlos(void); simple_rx_nlos();
    // extern int rx_sniff(void); rx_sniff();
    // extern int rx_with_xtal_trim(void); rx_with_xtal_trim();
    // extern int rx_diagnostics(void); rx_diagnostics();
    // extern int tx_sleep(void); tx_sleep();
    // extern int tx_sleep_idleRC(void); tx_sleep_idleRC();
    // extern int tx_timed_sleep(void); tx_timed_sleep();
    // extern int tx_sleep_auto(void); tx_sleep_auto();
    // extern int tx_with_cca(void); tx_with_cca();
    // extern int simple_tx_aes(void); simple_tx_aes();
    // extern int simple_rx_aes(void); simple_rx_aes();
    // extern int tx_wait_resp(void); tx_wait_resp();
    // extern int tx_wait_resp_int(void); tx_wait_resp_int();
    // extern int rx_send_resp(void); rx_send_resp();
    // extern int ss_twr_responder(void); ss_twr_responder();
    // extern int ss_twr_initiator(void); ss_twr_initiator();
    // extern int ss_twr_initiator_sts(void); ss_twr_initiator_sts();
    // extern int ss_twr_responder_sts(void); ss_twr_responder_sts();
    // extern int ss_twr_initiator_sts_no_data(void); ss_twr_initiator_sts_no_data();
    // extern int ss_twr_responder_sts_no_data(void); ss_twr_responder_sts_no_data();
    // extern int tx_rx_aes_verification(void); tx_rx_aes_verification();
    // extern int ss_aes_twr_initiator(void); ss_aes_twr_initiator();
    // extern int ss_aes_twr_responder(void); ss_aes_twr_responder();
    // extern int ds_twr_initiator(void); ds_twr_initiator();
    // extern int ds_twr_responder(void); ds_twr_responder();
    // extern int ds_twr_responder_sts(void); ds_twr_responder_sts();
    // extern int ds_twr_initiator_sts(void); ds_twr_initiator_sts();
    // extern int ds_twr_sts_sdc_initiator(void); ds_twr_sts_sdc_initiator();
    // extern int ds_twr_sts_sdc_responder(void); ds_twr_sts_sdc_responder();
    // extern int continuous_wave_example(void); continuous_wave_example();
    // extern int continuous_frame_example(void); continuous_frame_example();
    // extern int ack_data_rx(void); ack_data_rx();
    // extern int ack_data_tx(void); ack_data_tx();
    // extern int gpio_example(void); gpio_example();
    // extern int simple_tx_sts_sdc(void); simple_tx_sts_sdc();
    // extern int simple_rx_sts_sdc(void); simple_rx_sts_sdc();
    // extern int frame_filtering_tx(void); frame_filtering_tx();
    // extern int frame_filtering_rx(void); frame_filtering_rx();
    // extern int spi_crc(void); spi_crc();
    // extern int simple_rx_pdoa(void); simple_rx_pdoa();
    // extern int otp_write(void); otp_write();
    // extern int le_pend_tx(void); le_pend_tx();
    // extern int le_pend_rx(void); le_pend_rx();
    // extern int pll_cal(void); pll_cal();
    // extern int bw_cal(void); bw_cal();
    // extern int double_buffer_rx(void); double_buffer_rx();
    // extern int timer_example(void); timer_example();
    // extern int tx_power_adjustment_example(void); tx_power_adjustment_example();
    // extern int simple_aes(void); simple_aes();
#if defined(TAG_APP)

  tag_application(3);

#elif  defined(ANCHOR_APP)

  uint16_t coordinates_an1[3] = {0,360,310};  // In centimeters
  uint16_t coordinates_an2[3] = {0,1580,320};  // In centimeters
  uint16_t coordinates_an3[3] = {1497,1550,330};  // In centimeters
  uint16_t coordinates_an4[3] = {1497,360,340};  // In centimeters
  uint16_t coordinates_an5[3] = {1350,700,190};  // In centimeters
  uint16_t coordinates_an6[3] = {1350,1550,200};  // In centimeters
  uint16_t coordinates_an7[3] = {350,700,200};  // In centimeters
  uint16_t coordinates_an8[3] = {350,1550,190};  // In centimeters

  anchor_application(7,coordinates_an7);

#else
	#error "Define either TAG_APP or ANCHOR_APP before compiling."
#endif    

    ////int i = 0;
    //while (1) 
    //{
    //  //read_dev_id();
    //  //printf("Hello %d \n",i++);
    //  //test_run_info(data);
    //  some_function();
    //  nrf_delay_ms(1000);
    //}

    //ret_code_t ret;

    //ret = NRF_LOG_INIT(NULL);
    //APP_ERROR_CHECK(ret);

    //ret = nrf_drv_clock_init();
    //nrf_drv_clock_init();
    //APP_ERROR_CHECK(ret);

    //nrf_drv_clock_lfclk_request(NULL);

    //while (!nrf_drv_clock_lfclk_is_running())
    //{
    //    /* Just waiting */
    //}

    //usb_cdc_acm_init();
    

    //NRF_LOG_INFO("USB CDC ACM example started.");

    

    while (true)
    {
        //while (app_usbd_event_queue_process()) {
        //}
        // USB events are being handled
        
        //unsigned char data[] = "Hello\n";
        //usb_send_data(data, sizeof(data) - 1);
        //uart_send_string(data);
  
        //nrf_delay_ms(1000);

        //bsp_board_led_invert(1);

        //UNUSED_RETURN_VALUE(NRF_LOG_PROCESS());
        //__WFE();
    }
}

