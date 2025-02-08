/*
 * listener.c
 *
 *  Created on: Feb 1, 2025
 *      Author: Kavindu
 */

#include "listener.h"




extern void test_run_info(unsigned char *data);

extern dwt_config_t config_options;

/* Values for the PG_DELAY and TX_POWER registers reflect the bandwidth and power of the spectrum at the current
 * temperature. These values can be calibrated prior to taking reference measurements. See NOTE 2 below. */
extern dwt_txconfig_t txconfig_options;

/* Ranging Config Message frame format */
/* short - short address mode & Broadcast PAN_ID 0xFFFF */
static uint8_t tx_msg[] = { 0x41 , 0x88 , 0 , 0xFF , 0xFF , 0x01 , 0x00 , 0x02 , 0x00 , 0 , 0 , 0 , 0};



void listener(void)
{
	/* Configure SPI rate, DW3000 supports up to 36 MHz */
	port_set_dw_ic_spi_fastrate();

	/* Reset DW IC */
	reset_DWIC(); /* Target specific drive of RSTn line into DW IC low for a period. */

	Sleep(2); // Time needed for DW3000 to start up (transition from INIT_RC to IDLE_RC, or could wait for SPIRDY event)

	/* Probe for the correct device driver. */
	dwt_probe((struct dwt_probe_s *)&dw3000_probe_interf);

	while (!dwt_checkidlerc()) /* Need to make sure DW IC is in IDLE_RC before proceeding */ { };

	if (dwt_initialise(DWT_DW_INIT) == DWT_ERROR)
	{
		test_run_info((unsigned char *)"INIT FAILED     ");
		while (1) { };
	}

	/* Enabling LEDs here for debug so that for each TX the D1 LED will flash on DW3000 red eval-shield boards. */
	dwt_setleds(DWT_LEDS_ENABLE | DWT_LEDS_INIT_BLINK);

	/* Configure DW IC. See NOTE 8 below. */
	/* if the dwt_configure returns DWT_ERROR either the PLL or RX calibration has failed the host should reset the device */
	if (dwt_configure(&config_options))
	{
		test_run_info((unsigned char *)"CONFIG FAILED     ");
		while (1) { };
	}

	/* Configure the TX spectrum parameters (power, PG delay and PG count) */
	dwt_configuretxrf(&txconfig_options);

	//Todo: Set frame filtering options properly. IC address so on.
}



int listener(void)
{
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
			dwt_readrxdata(rx_buffer, frame_len-FCS_LEN, 0);

			/* TESTING BREAKPOINT LOCATION #1 */
			test_run_info((unsigned char *)"Frame Received");
			test_run_info((unsigned char *)&rx_buffer[2]);

			/* Clear good RX frame event in the DW IC status register. */
			dwt_writesysstatuslo(DWT_INT_RXFCG_BIT_MASK);


	//		int i;

	//		/* Copy source address of blink in response destination address. */ TODO
	//		for (i = 0; i < 8; i++)
	//		{
	//			tx_msg[DATA_FRAME_DEST_IDX + i] = rx_buffer[BLINK_FRAME_SRC_IDX + i];
	//		}

			/* Write response frame data to DW IC and prepare transmission. See NOTE 6 below.*/
			dwt_writetxdata(sizeof(tx_msg), tx_msg, 0); /* Zero offset in TX buffer. */
			dwt_writetxfctrl(sizeof(tx_msg), 0, 0);     /* Zero offset in TX buffer, no ranging. */

			/* Send the response. */
			dwt_starttx(DWT_START_TX_IMMEDIATE);

			/* Poll DW IC until TX frame sent event set. */
			waitforsysstatus(NULL, NULL, DWT_INT_TXFRS_BIT_MASK, 0);

			/* Clear TX frame sent event. */
			dwt_writesysstatuslo(DWT_INT_TXFRS_BIT_MASK);

			ret = 0;
		}

	}
	else
	{
		/* Clear RX error events in the DW IC status register. */
		dwt_writesysstatuslo(SYS_STATUS_ALL_RX_ERR);
	}

	return ret;
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











