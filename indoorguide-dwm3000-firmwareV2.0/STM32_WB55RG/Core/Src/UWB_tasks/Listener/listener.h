/*
 * listener.h
 *
 *  Created on: Feb 1, 2025
 *      Author: Kavindu
 */

#ifndef LISTENER_H
#define LISTENER_H


#include "deca_probe_interface.h"
#include <deca_device_api.h>
#include <deca_spi.h>
#include <port.h>
#include <shared_defines.h>
#include <shared_functions.h>

#include "../../Common/common_defines.h"



/* Index to access to source address of the blink frame in the rx_buffer array. */
#define BLINK_FRAME_SRC_IDX 10
/* Index to access the already fetched anchor addr 1 from BLINK frame  */
//#define BLINK_FRAME_FETCHED_AN_1_IDX 2
///* Index to access the already fetched anchor addr 2 from BLINK frame  */
//#define BLINK_FRAME_FETCHED_AN_2_IDX 4
///* Index to access the already fetched anchor addr 2 from BLINK frame  */
//#define BLINK_FRAME_FETCHED_AN_3_IDX 6
///* Index to access the already fetched anchor addr 2 from BLINK frame  */
//#define BLINK_FRAME_FETCHED_AN_4_IDX 8 //Todo: No need for these
#define BLINK_FRAME_FETCHED_AN_IDX_START 2
/* Index to access the Frame Control (FC) bytes of BLINK frame*/
#define BLINK_FRAME_FC_IDX           0



/* Index to access to sequence number of the ranging config frame in the tx_msg array. */
#define RNG_CFG_FRAME_SN_IDX   2
/* Index to access the destination address (current tag) from ranging config frame */
#define RNG_CFG_FRAME_DEST_IDX 5
/* Index to access the source address of the anchor from ranging config frame*/
#define RNG_CFG_FRAME_SRC_IDX  7
/* Index to access to X cordinate of the anchor from incoming ranging config frame*/
#define RNG_CFG_FRAME_AN_X_IDX 10
/* Index to access to Y cordinate of the anchor from incoming ranging config frame*/
#define RNG_CFG_FRAME_AN_Y_IDX 12
/* Index to access to Z cordinate of the anchor from incoming ranging config frame*/
#define RNG_CFG_FRAME_AN_Z_IDX 14
/* Common part of all ranging frames */
#define ALL_MSG_COMMON_LEN     10




void listener_init(anchorinfo_t *anchor);

void listener_reinit(void);

int listener(anchorinfo_t *anchor);






#endif /* LISTENER_H */
