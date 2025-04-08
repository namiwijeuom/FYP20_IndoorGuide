#include "uart.h"
#include "nrf_drv_uart.h"
#include "app_error.h"
#include "nrf_delay.h"

#include "custom_board.h"

// UART Instance
static const nrf_drv_uart_t uart_instance = NRF_DRV_UART_INSTANCE(0);

// UART Event Handler (optional)
static void uart_event_handler(nrf_drv_uart_event_t * p_event, void * p_context) {
    // Handle UART events if needed
}

// Initialize UART
void uart_init(void) {
    nrf_drv_uart_config_t uart_config = NRF_DRV_UART_DEFAULT_CONFIG;
    uart_config.pseltxd = TX_PIN_NUMBER; // Set your TX pin
    uart_config.pselrxd = RX_PIN_NUMBER; // Set your RX pin
    uart_config.baudrate = NRF_UART_BAUDRATE_115200; // Match this with Tera Term
    uart_config.hwfc = NRF_UART_HWFC_DISABLED; // Flow control disabled
    uart_config.parity = NRF_UART_PARITY_EXCLUDED; // No parity

    ret_code_t err_code = nrf_drv_uart_init(&uart_instance, &uart_config, uart_event_handler);
    //APP_ERROR_CHECK(err_code);
}

// Send a string over UART
void uart_send_string(unsigned char * str) {
    while (*str) {
        ret_code_t err_code = nrf_drv_uart_tx(&uart_instance, (uint8_t *)str, 1);
        //APP_ERROR_CHECK(err_code);
        str++;
        nrf_delay_ms(1); // Small delay between characters (adjust as needed)
    }
}