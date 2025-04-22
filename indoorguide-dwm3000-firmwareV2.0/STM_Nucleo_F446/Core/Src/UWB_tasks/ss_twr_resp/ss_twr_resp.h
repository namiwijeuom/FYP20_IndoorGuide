/*
 * ss_twr_resp.h
 *
 *  Created on: Feb 2, 2025
 *      Author: Kavindu
 */

#ifndef SS_TWR_RESPONDER_H
#define SS_TWR_RESPONDER_H


#include "deca_probe_interface.h"
#include <deca_device_api.h>
#include <deca_spi.h>
#include <port.h>
#include <shared_defines.h>
#include <shared_functions.h>

#include "../../Common/common_defines.h"




/* Default antenna delay values for 64 MHz PRF. See NOTE 2 below. */
#define TX_ANT_DLY 16385
#define RX_ANT_DLY 16385


/* Length of the common part of the message (up to and including the function code, see NOTE 3 below). */
#define ALL_MSG_COMMON_LEN 10
/* Index to access some of the fields in the frames involved in the process. */
#define ALL_MSG_SN_IDX          2
#define RESP_MSG_POLL_RX_TS_IDX 10
#define RESP_MSG_RESP_TX_TS_IDX 14
#define RESP_MSG_TS_LEN         4

#define POLL_MSG_FRAME_DEST_IDX  5
#define POLL_MSG_FRAME_SRC_IDX   7

#define RESP_MSG_FRAME_DEST_IDX  5
#define RESP_MSG_FRAME_SRC_IDX   7


void ss_twr_responder_init(anchorinfo_t *anchor);

void ss_twr_responder_reinit(anchorinfo_t *anchor);

int ss_twr_responder(void);









#endif /* SS_TWR_RESPONDER_H */
