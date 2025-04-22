#ifndef USB_H
#define USB_H

#include <stdint.h>
#include <stdbool.h>
#include "app_usbd_cdc_acm.h"


#ifdef __cplusplus
extern "C" {
#endif

void usb_cdc_acm_init(void);
void usb_send_data(uint8_t *tx_buffer, int size);
#endif // USB_H
