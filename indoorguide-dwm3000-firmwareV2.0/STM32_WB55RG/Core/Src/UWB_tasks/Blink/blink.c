/*
 * blink.c
 *
 *  Created on: Feb 1, 2025
 *      Author: Kavindu
 */


#include "blink.h"

                                                           /* LSB    MSB */
static uint8_t tx_msg[] = { 0xC5, 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0x01 , 0x00 , 0 , 0 };

/* Buffer to store received frame. See NOTE 5 below. */
static uint8_t rx_buffer[FRAME_LEN_MAX];


extern void test_run_info(unsigned char *data);

extern dwt_config_t config_options;

/* Values for the PG_DELAY and TX_POWER registers reflect the bandwidth and power of the spectrum at the current
 * temperature. These values can be calibrated prior to taking reference measurements. See NOTE 2 below. */
extern dwt_txconfig_t txconfig_options;


void blink_init(void)
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

    //* Enabling LEDs here for debug so that for each TX the D1 LED will flash on DW3000 red eval-shield boards. */
	dwt_setleds(DWT_LEDS_ENABLE | DWT_LEDS_INIT_BLINK);

    /* Configure DW IC. See NOTE 2 below. */
    /* if the dwt_configure returns DWT_ERROR either the PLL or RX calibration has failed the host should reset the device */
    if (dwt_configure(&config_options))
    {
        test_run_info((unsigned char *)"CONFIG FAILED     ");
        while (1) { };
    }

    /* Configure the TX spectrum parameters (power, PG delay and PG count) */
    dwt_configuretxrf(&txconfig_options);

    /* Set delay to turn reception on after transmission of the frame. See NOTE 3 below. */
    dwt_setrxaftertxdelay(TX_TO_RX_DELAY_UUS);

    /* Set response frame timeout. */
    dwt_setrxtimeout(RX_RESP_TO_UUS);

    //TODO : Set dwmIC long, short addresses, frame filtering, pan id, so on.
}


int blink(void)
{
    /* Hold copy of status register state here for reference so that it can be examined at a debug breakpoint. */
    uint32_t status_reg = 0;
    /* Hold copy of frame length of frame received (if good) so that it can be examined at a debug breakpoint. */
    uint16_t frame_len = 0;

    int ret = -1; // success or fail.


	/* Write frame data to DW3000 and prepare transmission. See NOTE 7 below. */
	dwt_writetxdata(sizeof(tx_msg), tx_msg, 0); /* Zero offset in TX buffer. */
	dwt_writetxfctrl(sizeof(tx_msg), 0, 0);     /* Zero offset in TX buffer, no ranging. */

	/* Start transmission, indicating that a response is expected so that reception is enabled immediately after the frame is sent. */
	dwt_starttx(DWT_START_TX_IMMEDIATE | DWT_RESPONSE_EXPECTED);

	/* We assume that the transmission is achieved normally, now poll for reception of a frame or error/timeout. See NOTE 8 below. */
	waitforsysstatus(&status_reg, NULL, (DWT_INT_RXFCG_BIT_MASK | SYS_STATUS_ALL_RX_TO | SYS_STATUS_ALL_RX_ERR), 0);

	if (status_reg & DWT_INT_RXFCG_BIT_MASK)
	{
		int i;

		/* Clear local RX buffer to avoid having leftovers from previous receptions. This is not necessary but is included here to aid reading
		 * the RX buffer. */
		for (i = 0; i < FRAME_LEN_MAX; i++)
		{
			rx_buffer[i] = 0;
		}

		/* A frame has been received, copy it to our local buffer. */
		frame_len = dwt_getframelength();
		if (frame_len <= FRAME_LEN_MAX)
		{
			dwt_readrxdata(rx_buffer, frame_len - FCS_LEN, 0); /* No need to read the FCS/CRC. */

			ret = 0;
		}

		/* TESTING BREAKPOINT LOCATION #1 */

		test_run_info((unsigned char *)"Frame Received");
		test_run_info((unsigned char *)&rx_buffer[2]);

		/* At this point, received frame can be examined in global "rx_buffer". An actual application would, for example, start by checking that
		 * the format and/or data of the response are the expected ones. A developer might put a breakpoint here to examine this frame. */

		/* Clear good RX frame event in the DW IC status register. */
		dwt_writesysstatuslo(DWT_INT_RXFCG_BIT_MASK);
	}
	else
	{
		/* Clear RX error/timeout events in the DW3000 status register. */
		dwt_writesysstatuslo(SYS_STATUS_ALL_RX_TO | SYS_STATUS_ALL_RX_ERR);

	}

	return ret;

}






/*****************************************************************************************************************************************************
 * NOTES:
 *
 * 1. The device ID is a hard coded constant in the blink to keep the example simple but for a real product every device should have a unique ID.
 *    For development purposes it is possible to generate a DW IC unique ID by combining the Lot ID & Part Number values programmed into the
 *    DW IC during its manufacture. However there is no guarantee this will not conflict with someone else�s implementation. We recommended that
 *    customers buy a block of addresses from the IEEE Registration Authority for their production items. See "EUI" in the DW IC User Manual.
 * 2. In this example, the DW IC is put into IDLE state after calling dwt_initialise(). This means that a fast SPI rate of up to 20 MHz can be used
 *    thereafter.
 * 3. TX to RX delay can be set to 0 to activate reception immediately after transmission. But, on the responder side, it takes time to process the
 *    received frame and generate the response (this has been measured experimentally to be around 70 �s). Using an RX to TX delay slightly less than
 *    this minimum turn-around time allows the application to make the communication efficient while reducing power consumption by adjusting the time
 *    spent with the receiver activated.
 * 4. This timeout is for complete reception of a frame, i.e. timeout duration must take into account the length of the expected frame. Here the value
 *    is arbitrary but chosen large enough to make sure that there is enough time to receive a complete frame sent by the "RX then send a response"
 *    example at the 110k data rate used (around 3 ms).
 * 5. In this example, maximum frame length is set to 127 bytes which is 802.15.4 UWB standard maximum frame length. DW IC supports an extended frame
 *    length (up to 1023 bytes long) mode which is not used in this example.
 * 6. In a real application, for optimum performance within regulatory limits, it may be necessary to set TX pulse bandwidth and TX power, (using
 *    the dwt_configuretxrf API call) to per device calibrated values saved in the target system or the DW IC OTP memory.
 * 7. dwt_writetxdata() takes the full size of tx_msg as a parameter but only copies (size - 2) bytes as the check-sum at the end of the frame is
 *    automatically appended by the DW IC. This means that our tx_msg could be two bytes shorter without losing any data (but the sizeof would not
 *    work anymore then as we would still have to indicate the full length of the frame to dwt_writetxdata()).
 * 8. We use polled mode of operation here to keep the example as simple as possible but all status events can be used to generate interrupts. Please
 *    refer to DW IC User Manual for more details on "interrupts".
 * 9. The user is referred to DecaRanging ARM application (distributed with EVK1000 product) for additional practical example of usage, and to the
 *    DW IC API Guide for more details on the DW IC driver functions.
 *10. TX and RX activity can be monitored using the following GPIOs (e.g. connected to an oscilloscope):
 *        - GPIO 2: RXLED signal. Driven high from the activation of reception for the LED blink time (~ 225 ms). If the reception remains activated
 *          for longer than that, this signal turns into a periodic signal where both ON and OFF phases last for LED blink time.
 *        - GPIO 3: TXLED signal. Driven high from the start of a transmission for the LED blink time.
 *        - GPIO 5: EXTTXE signal. Follows the transmitter enabled state.
 *        - GPIO 6: EXTRXE signal. Follows the receiver enabled state.
 *11. Desired configuration by user may be different to the current programmed configuration. dwt_configure is called to set desired
 *    configuration.
 ****************************************************************************************************************************************************/






