/*
 * ss_twr_init.c
 *
 *  Created on: Feb 2, 2025
 *      Author: Kavindu
 */

#include <stdint.h>
#include <string.h>
#include "ss_twr_init.h"




extern void test_run_info(unsigned char *data);


/* Frames used in the ranging process. See NOTE 3 below. */// lsb msb lsb msb fcode
static uint8_t tx_poll_msg[] = { 0x41, 0x88, 0, 0xFF, 0xFF, 0 , 0 , 0 , 0 , 0x84, 0, 0 };
static uint8_t rx_resp_msg[] = { 0x41, 0x88, 0, 0xFF, 0xFF, 0 , 0 , 0 , 0 , 0x72, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };


/* Frame sequence number, incremented after each transmission. */
//static uint8_t frame_seq_nb = 0;

/* Buffer to store received response message.
 * Its size is adjusted to longest frame that this example code is supposed to handle. */
#define RX_BUF_LEN 20
static uint8_t rx_buffer[RX_BUF_LEN];

/* Hold copy of status register state here for reference so that it can be examined at a debug breakpoint. */
static uint32_t status_reg = 0;





/* Hold copies of computed time of flight and distance here for reference so that it can be examined at a debug breakpoint. */
static double tof;
static double distance;

/* Values for the PG_DELAY and TX_POWER registers reflect the bandwidth and power of the spectrum at the current
 * temperature. These values can be calibrated prior to taking reference measurements. See NOTE 2 below. */
extern dwt_txconfig_t txconfig_options;
extern dwt_config_t config_options;



void ss_twr_initiator_init(taginfo_t *tag)
{

	for(uint8_t i = 0 ; i < ADDR_SHORT_BYTES ; i++)
	{
		tx_poll_msg[POLL_MSG_FRAME_SRC_IDX+i] = tag->short_addr[i];
		rx_resp_msg[RESP_MSG_FRAME_DEST_IDX+i] = tag->short_addr[i];
	}

}



void ss_twr_initiator_reinit(taginfo_t *tag)
{
	/* Set expected response's delay and timeout. See NOTE 1 and 5 below.
	 * As this example only handles one incoming frame with always the same delay and timeout, those values can be set here once for all. */
	dwt_setrxaftertxdelay(POLL_TX_TO_RESP_RX_DLY_UUS);
	dwt_setrxtimeout(RESP_RX_TIMEOUT_UUS);

	for(uint8_t i = 0 ; i < ADDR_SHORT_BYTES ; i++)
	{
		tx_poll_msg[POLL_MSG_FRAME_DEST_IDX+i] = tag->current_anchor.short_addr[i];
		rx_resp_msg[RESP_MSG_FRAME_SRC_IDX+i]  = tag->current_anchor.short_addr[i];
	}
}



int ss_twr_initiator(taginfo_t *tag)
{
	int ret = -1;
	/* Write frame data to DW IC and prepare transmission. See NOTE 7 below. */
	//tx_poll_msg[ALL_MSG_SN_IDX] = frame_seq_nb;  // Set sequence number if needed.
	dwt_writesysstatuslo(DWT_INT_TXFRS_BIT_MASK);
	dwt_writetxdata(sizeof(tx_poll_msg), tx_poll_msg, 0); /* Zero offset in TX buffer. */
	dwt_writetxfctrl(sizeof(tx_poll_msg), 0, 1);          /* Zero offset in TX buffer, ranging. */

	/* Start transmission, indicating that a response is expected so that reception is enabled automatically after the frame is sent and the delay
	 * set by dwt_setrxaftertxdelay() has elapsed. */
	dwt_starttx(DWT_START_TX_IMMEDIATE | DWT_RESPONSE_EXPECTED);

	/* We assume that the transmission is achieved correctly, poll for reception of a frame or error/timeout. See NOTE 8 below. */
	waitforsysstatus(&status_reg, NULL, (DWT_INT_RXFCG_BIT_MASK | SYS_STATUS_ALL_RX_TO | SYS_STATUS_ALL_RX_ERR), 0);

	/* Increment frame sequence number after transmission of the poll message (modulo 256). */
	//frame_seq_nb++;

	if (status_reg & DWT_INT_RXFCG_BIT_MASK)
	{
		uint16_t frame_len;

		/* Clear good RX frame event in the DW IC status register. */
		dwt_writesysstatuslo(DWT_INT_RXFCG_BIT_MASK);

		/* A frame has been received, read it into the local buffer. */
		frame_len = dwt_getframelength();
		if (frame_len <= sizeof(rx_buffer))
		{
			dwt_readrxdata(rx_buffer, frame_len, 0);

			/* Check that the frame is the expected response from the companion "SS TWR responder" example.
			 * As the sequence number field of the frame is not relevant, it is cleared to simplify the validation of the frame. */
			rx_buffer[ALL_MSG_SN_IDX] = 0;
			if (memcmp(rx_buffer, rx_resp_msg, ALL_MSG_COMMON_LEN) == 0)
			{
				uint32_t poll_tx_ts, resp_rx_ts, poll_rx_ts, resp_tx_ts;
				int32_t rtd_init, rtd_resp;
				float clockOffsetRatio;

				/* Retrieve poll transmission and response reception timestamps. See NOTE 9 below. */
				poll_tx_ts = dwt_readtxtimestamplo32();
				resp_rx_ts = dwt_readrxtimestamplo32();

				/* Read carrier integrator value and calculate clock offset ratio. See NOTE 11 below. */
				clockOffsetRatio = ((float)dwt_readclockoffset()) / (uint32_t)(1 << 26);

				/* Get timestamps embedded in response message. */
				resp_msg_get_ts(&rx_buffer[RESP_MSG_POLL_RX_TS_IDX], &poll_rx_ts);
				resp_msg_get_ts(&rx_buffer[RESP_MSG_RESP_TX_TS_IDX], &resp_tx_ts);

				/* Compute time of flight and distance, using clock offset ratio to correct for differing local and remote clock rates */
				rtd_init = resp_rx_ts - poll_tx_ts;
				rtd_resp = resp_tx_ts - poll_rx_ts;

				tof = ((rtd_init - rtd_resp * (1 - clockOffsetRatio)) / 2.0) * DWT_TIME_UNITS;
				distance = tof * SPEED_OF_LIGHT;
				/* Display computed distance on LCD. */

//				uint16_t anchor_name = GET_UINT16(tag->current_anchor.short_addr[0],tag->current_anchor.short_addr[1]);
//
//				snprintf(dist_str, sizeof(dist_str), "AN %d  DIST: %3.2f m",anchor_name, distance);
//				test_run_info((unsigned char *)dist_str);

				tag->distance = distance * 100; // In centimeters

				ret = 0;
			}
		}
	}
	else
	{
		/* Clear RX error/timeout events in the DW IC status register. */
		dwt_writesysstatuslo(SYS_STATUS_ALL_RX_TO | SYS_STATUS_ALL_RX_ERR);
	}

	return ret;
}




/*****************************************************************************************************************************************************
 * NOTES:
 *
 * 1. The single-sided two-way ranging scheme implemented here has to be considered carefully as the accuracy of the distance measured is highly
 *    sensitive to the clock offset error between the devices and the length of the response delay between frames. To achieve the best possible
 *    accuracy, this response delay must be kept as low as possible. In order to do so, 6.8 Mbps data rate is used in this example and the response
 *    delay between frames is defined as low as possible. The user is referred to User Manual for more details about the single-sided two-way ranging
 *    process.  NB:SEE ALSO NOTE 11.
 *
 *    Initiator: |Poll TX| ..... |Resp RX|
 *    Responder: |Poll RX| ..... |Resp TX|
 *                   ^|P RMARKER|                    - time of Poll TX/RX
 *                                   ^|R RMARKER|    - time of Resp TX/RX
 *
 *                       <--TDLY->                   - POLL_TX_TO_RESP_RX_DLY_UUS (RDLY-RLEN)
 *                               <-RLEN->            - RESP_RX_TIMEOUT_UUS   (length of response frame)
 *                    <----RDLY------>               - POLL_RX_TO_RESP_TX_DLY_UUS (depends on how quickly responder can turn around and reply)
 *
 *
 * 2. The sum of the values is the TX to RX antenna delay, this should be experimentally determined by a calibration process. Here we use a hard coded
 *    value (expected to be a little low so a positive error will be seen on the resultant distance estimate). For a real production application, each
 *    device should have its own antenna delay properly calibrated to get good precision when performing range measurements.
 * 3. The frames used here are Decawave specific ranging frames, complying with the IEEE 802.15.4 standard data frame encoding. The frames are the
 *    following:
 *     - a poll message sent by the initiator to trigger the ranging exchange.
 *     - a response message sent by the responder to complete the exchange and provide all information needed by the initiator to compute the
 *       time-of-flight (distance) estimate.
 *    The first 10 bytes of those frame are common and are composed of the following fields:
 *     - byte 0/1: frame control (0x8841 to indicate a data frame using 16-bit addressing).
 *     - byte 2: sequence number, incremented for each new frame.
 *     - byte 3/4: PAN ID (0xDECA).
 *     - byte 5/6: destination address, see NOTE 4 below.
 *     - byte 7/8: source address, see NOTE 4 below.
 *     - byte 9: function code (specific values to indicate which message it is in the ranging process).
 *    The remaining bytes are specific to each message as follows:
 *    Poll message:
 *     - no more data
 *    Response message:
 *     - byte 10 -> 13: poll message reception timestamp.
 *     - byte 14 -> 17: response message transmission timestamp.
 *    All messages end with a 2-byte checksum automatically set by DW IC.
 * 4. Source and destination addresses are hard coded constants in this example to keep it simple but for a real product every device should have a
 *    unique ID. Here, 16-bit addressing is used to keep the messages as short as possible but, in an actual application, this should be done only
 *    after an exchange of specific messages used to define those short addresses for each device participating to the ranging exchange.
 * 5. This timeout is for complete reception of a frame, i.e. timeout duration must take into account the length of the expected frame. Here the value
 *    is arbitrary but chosen large enough to make sure that there is enough time to receive the complete response frame sent by the responder at the
 *    6.8M data rate used (around 400 �s).
 * 6. In a real application, for optimum performance within regulatory limits, it may be necessary to set TX pulse bandwidth and TX power, (using
 *    the dwt_configuretxrf API call) to per device calibrated values saved in the target system or the DW IC OTP memory.
 * 7. dwt_writetxdata() takes the full size of the message as a parameter but only copies (size - 2) bytes as the check-sum at the end of the frame is
 *    automatically appended by the DW IC. This means that our variable could be two bytes shorter without losing any data (but the sizeof would not
 *    work anymore then as we would still have to indicate the full length of the frame to dwt_writetxdata()).
 * 8. We use polled mode of operation here to keep the example as simple as possible but all status events can be used to generate interrupts. Please
 *    refer to DW IC User Manual for more details on "interrupts". It is also to be noted that STATUS register is 5 bytes long but, as the event we
 *    use are all in the first bytes of the register, we can use the simple dwt_read32bitreg() API call to access it instead of reading the whole 5
 *    bytes.
 * 9. The high order byte of each 40-bit time-stamps is discarded here. This is acceptable as, on each device, those time-stamps are not separated by
 *    more than 2**32 device time units (which is around 67 ms) which means that the calculation of the round-trip delays can be handled by a 32-bit
 *    subtraction.
 * 10. The user is referred to DecaRanging ARM application (distributed with EVK1000 product) for additional practical example of usage, and to the
 *     DW IC API Guide for more details on the DW IC driver functions.
 * 11. The use of the clock offset value to correct the TOF calculation, significantly improves the result of the SS-TWR where the remote
 *     responder unit's clock is a number of PPM offset from the local initiator unit's clock.
 *     As stated in NOTE 2 a fixed offset in range will be seen unless the antenna delay is calibrated and set correctly.
 * 12. In this example, the DW IC is put into IDLE state after calling dwt_initialise(). This means that a fast SPI rate of up to 20 MHz can be used
 *     thereafter.
 * 13. Desired configuration by user may be different to the current programmed configuration. dwt_configure is called to set desired
 *     configuration.
 ****************************************************************************************************************************************************/






