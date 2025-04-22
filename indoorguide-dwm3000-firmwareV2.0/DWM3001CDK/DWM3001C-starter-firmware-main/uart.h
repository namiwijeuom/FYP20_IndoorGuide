#ifndef UART_H
#define UART_H

#include <stdint.h>
#include <stdbool.h>
#include "nrf_drv_uart.h"

//// UART Pin Configuration
//#define TX_PIN_NUMBER 6  // Replace with your TX pin
//#define RX_PIN_NUMBER 8  // Replace with your RX pin

// UART Baud Rate
#define UART_BAUDRATE 115200

// Function Declarations
void uart_init(void);
void uart_send_string(unsigned char * str);

#endif // UART_H