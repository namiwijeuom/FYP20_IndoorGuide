/*
 * blink.h
 *
 *  Created on: Feb 1, 2025
 *      Author: Kavindu
 */

#ifndef BLINK_H
#define BLINK_H


#include "deca_probe_interface.h"
#include "deca_device_api.h"
#include "deca_spi.h"
#include "port.h"
#include "shared_defines.h"
#include "shared_functions.h"




/* Index to access to sequence number of the blink frame in the tx_msg array. */
#define BLINK_FRAME_SN_IDX 1

/* Delay from end of transmission to activation of reception, expressed in UWB microseconds (1 uus is 512/499.2 microseconds). See NOTE 2 below. */
#define TX_TO_RX_DELAY_UUS 60

/* Receive response timeout, expressed in UWB microseconds. See NOTE 4 below. */
#define RX_RESP_TO_UUS 5000



/*
 * @fn anchor_init
 *
 * @brief Anchor initialization with given Anchor ID.
 *
 * @param  uint8_t anchorID
 *
 * @return none
 */

void blink_init(void);

int blink(void);






#endif /* BLINK_H */
