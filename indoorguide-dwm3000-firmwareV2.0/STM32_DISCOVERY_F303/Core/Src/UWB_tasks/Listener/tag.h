/*
 * tag.h
 *
 *  Created on: Dec 23, 2024
 *      Author: User
 */

#ifndef TAG_H
#define TAG_H


#include "deca_probe_interface.h"
#include "config_options.h"
#include "deca_device_api.h"
#include "deca_spi.h"
#include "port.h"
#include "shared_defines.h"
#include "shared_functions.h"



extern void test_run_info(unsigned char *data);


/* Default communication configuration. We use default non-STS DW mode. */
static dwt_config_t config = {
    5,                /* Channel number. */
    DWT_PLEN_128,     /* Preamble length. Used in TX only. */
    DWT_PAC8,         /* Preamble acquisition chunk size. Used in RX only. */
    9,                /* TX preamble code. Used in TX only. */
    9,                /* RX preamble code. Used in RX only. */
    1,                /* 0 to use standard 8 symbol SFD, 1 to use non-standard 8 symbol, 2 for non-standard 16 symbol SFD and 3 for 4z 8 symbol SDF type */
    DWT_BR_6M8,       /* Data rate. */
    DWT_PHRMODE_STD,  /* PHY header mode. */
    DWT_PHRRATE_STD,  /* PHY header rate. */
    (129 + 8 - 8),    /* SFD timeout (preamble length + 1 + SFD length - PAC size). Used in RX only. */
    DWT_STS_MODE_OFF, /* STS disabled */
    DWT_STS_LEN_64,   /* STS length see allowed values in Enum dwt_sts_lengths_e */
    DWT_PDOA_M0       /* PDOA mode off */
};

/* Inter-ranging delay period, in milliseconds. */
#define RNG_DELAY_MS 1000

/* Default antenna delay values for 64 MHz PRF. See NOTE 2 below. */
#define TX_ANT_DLY 16385
#define RX_ANT_DLY 16385


/* Length of the common part of the message (up to and including the function code, see NOTE 3 below). */
#define ALL_MSG_COMMON_LEN 9
/* Indexes to access some of the fields in the frames defined above. */
#define ALL_MSG_SN_IDX          2
#define RESP_MSG_POLL_RX_TS_IDX 10
#define RESP_MSG_RESP_TX_TS_IDX 14
#define RESP_MSG_TS_LEN         4


#define DESTINATION_ID_IDX  5
#define SOURCE_ID_IDX       7






/*
 * @fn tag_init
 *
 * @brief Tag initialization with given tag ID.
 *
 * @param  uint8_t tagID
 *
 * @return none
 */

void tag_init(uint8_t tagID);


void start_ss_ranging(uint8_t anchorID,double measurements[]);






#endif /* TAG_H */
