/*
 * listener.c
 *
 *  Created on: Feb 1, 2025
 *      Author: Kavindu
 */

#include <string.h>
#include "listener.h"




extern void test_run_info(unsigned char *data);


extern dwt_config_t config_options;

/* Values for the PG_DELAY and TX_POWER registers reflect the bandwidth and power of the spectrum at the current
 * temperature. These values can be calibrated prior to taking reference measurements. See NOTE 2 below. */
extern dwt_txconfig_t txconfig_options;


/* Buffer to store received frame. See NOTE 1 below. */
static uint8_t rx_buffer[FRAME_LEN_MAX];


/* Ranging Config Message frame format */ // Todo: add a description about frame format here.
/* short - short address mode & Broadcast PAN_ID 0xFFFF *//* LSB   MSB   LSB    MSB   fcode */
static uint8_t tx_msg[] = { 0x41 , 0x88 , 0 , 0xFF , 0xFF ,   0 ,   0 ,   0  ,   0  , 0x20 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0};


/* Private function prototypes Begin */
int is_already_fetched(uint8_t *msg, uint16_t anchor_addr);
/* Private function prototypes End */




void listener_init(anchorinfo_t *anchor)
{

	for(uint8_t i = 0; i < ADDR_SHORT_BYTES; i++)
	{
		tx_msg[RNG_CFG_FRAME_SRC_IDX+i] = anchor->short_addr[i];
	}

	for(uint8_t i = 0; i < CORD_BYTES_LEN; i++)
	{
		tx_msg[RNG_CFG_FRAME_AN_X_IDX+i] = (uint8_t)(anchor->loc_x >> (8*i));
		tx_msg[RNG_CFG_FRAME_AN_Y_IDX+i] = (uint8_t)(anchor->loc_y >> (8*i));
		tx_msg[RNG_CFG_FRAME_AN_Z_IDX+i] = (uint8_t)(anchor->loc_z >> (8*i));

	}

}



void listener_reinit(void)
{
	/* Disable frame filtering to get any incoming BLINK frame */
	dwt_configureframefilter(DWT_FF_DISABLE,DWT_FF_DATA_EN);

}



int listener(anchorinfo_t *anchor)
{
	/* Hold copy of status register state here for reference so that it can be examined at a debug breakpoint. */
	uint32_t status_reg = 0;
	/* Hold copy of frame length of frame received (if good) so that it can be examined at a debug breakpoint. */
	uint16_t frame_len = 0;

	int ret = -1; // Success or fail.


	/* Activate reception immediately. See NOTE 4 below. */
	dwt_rxenable(DWT_START_RX_IMMEDIATE);

	/* Poll until a frame is properly received or an error occurs. See NOTE 5 below.
	 * STATUS register is 5 bytes long but, as the events we are looking at are in the lower bytes of the register, we can use this simplest API
	 * function to access it. */
	waitforsysstatus(&status_reg, NULL, (DWT_INT_RXFCG_BIT_MASK | SYS_STATUS_ALL_RX_ERR), 0);

	if (status_reg & DWT_INT_RXFCG_BIT_MASK)
	{
		/* A frame has been received, read it into the local buffer. */
		frame_len = dwt_getframelength();
		if (frame_len <= FRAME_LEN_MAX)
		{
			dwt_readrxdata(rx_buffer, frame_len , 0);

			if(rx_buffer[BLINK_FRAME_FC_IDX] == 0xC5)        // Confirming it is a Blink frame
			{												 // Todo: Do this filtering using DWT_configureframefilter()
				uint16_t anchor_addr = GET_UINT16(anchor->short_addr[0],anchor->short_addr[1]);

				if(!is_already_fetched(rx_buffer, anchor_addr)) // Checking already fetched one or not.
				{

					/* TESTING BREAKPOINT LOCATION #1 */
					test_run_info((unsigned char *)"Frame Received");
					//test_run_info((unsigned char *)&rx_buffer[2]);

					/* Clear good RX frame event in the DW IC status register. */
					dwt_writesysstatuslo(DWT_INT_RXFCG_BIT_MASK);

					for(uint8_t i = 0 ; i < ADDR_SHORT_BYTES ; i++)
					{
						anchor->current_tag_addr[i] = rx_buffer[BLINK_FRAME_SRC_IDX+i];
						tx_msg[RNG_CFG_FRAME_DEST_IDX+i] = rx_buffer[BLINK_FRAME_SRC_IDX+i];
					}
					// Todo: set Sequence Number too.

					/* Write response frame data to DW IC and prepare transmission. See NOTE 6 below.*/
					dwt_writetxdata(sizeof(tx_msg), tx_msg, 0); /* Zero offset in TX buffer. */
					dwt_writetxfctrl(sizeof(tx_msg), 0, 0);     /* Zero offset in TX buffer, no ranging. */

					/* Send the response. */
					dwt_starttx(DWT_START_TX_IMMEDIATE);

					/* Poll DW IC until TX frame sent event set. */
					waitforsysstatus(NULL, NULL, DWT_INT_TXFRS_BIT_MASK, 0);

					/* Clear TX frame sent event. */
					dwt_writesysstatuslo(DWT_INT_TXFRS_BIT_MASK);

	//				/* Enabling frame filter for incoming POLL_MSG with correct 16-bit destination short address*/
	//				dwt_configureframefilter(DWT_FF_ENABLE_802_15_4, DWT_FF_DATA_EN); //Todo: Maybe add this to ss_twr_responder_reinit()

					ret = 0;
				}
			}
		}

	}
	else
	{
		/* Clear RX error events in the DW IC status register. */
		dwt_writesysstatuslo(SYS_STATUS_ALL_RX_ERR);
	}

	return ret;
}



/* Private function definitions */
int is_already_fetched(uint8_t *msg, uint16_t anchor_addr)
{
    for (int i = BLINK_FRAME_FETCHED_AN_IDX_START; i <= 9; i += 2)
    {  // Iterate over LSB-MSB pairs
        uint16_t extracted_addr = GET_UINT16(msg[i],msg[i+1]);  // Reconstruct uint16_t from LSB and MSB

        if (extracted_addr == anchor_addr)
        {
            return 1;  // Found
        }
    }
    return 0;  // Not found
}


/*****************************************************************************************************************************************************
 * NOTES:
 *
 * 1. In this example, maximum frame length is set to 127 bytes which is 802.15.4 UWB standard maximum frame length. DW IC supports an extended frame
 *    length (up to 1023 bytes long) mode which is not used in this example.
 * 2. In this example, the DW IC is put into IDLE state after calling dwt_initialise(). This means that a fast SPI rate of up to 20 MHz can be used
 *    thereafter.
 * 3. In a real application, for optimum performance within regulatory limits, it may be necessary to set TX pulse bandwidth and TX power, (using
 *    the dwt_configuretxrf API call) to per device calibrated values saved in the target system or the DW IC OTP memory.
 * 4. Manual reception activation is performed here but DW IC offers several features that can be used to handle more complex scenarios or to
 *    optimise system's overall performance (e.g. timeout after a given time, automatic re-enabling of reception in case of errors, etc.).
 * 5. We use polled mode of operation here to keep the example as simple as possible but all status events can be used to generate interrupts. Please
 *    refer to DW IC User Manual for more details on "interrupts".
 * 6. dwt_writetxdata() takes the full size of tx_msg as a parameter but only copies (size - 2) bytes as the check-sum at the end of the frame is
 *    automatically appended by the DW IC. This means that our tx_msg could be two bytes shorter without losing any data (but the sizeof would not
 *    work anymore then as we would still have to indicate the full length of the frame to dwt_writetxdata()).
 * 7. The user is referred to DecaRanging ARM application (distributed with EVK1000 product) for additional practical example of usage, and to the
 *    DW IC API Guide for more details on the DW IC driver functions.
 * 8. Desired configuration by user may be different to the current programmed configuration. dwt_configure is called to set desired
 *    configuration.
 ****************************************************************************************************************************************************/











