/*
 * anchor_app.c
 *
 *  Created on: Dec 23, 2024
 *      Author: kavindu
 */
#include "anchor_app.h"


extern void test_run_info(unsigned char *data);


extern dwt_config_t config_options;

/* Values for the PG_DELAY and TX_POWER registers reflect the bandwidth and power of the spectrum at the current
 * temperature. These values can be calibrated prior to taking reference measurements. See NOTE 2 below. */
extern dwt_txconfig_t txconfig_options;


anchorinfo_t anchorDevice;


void anchor_uwb_init(anchorinfo_t *anchor)
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

	/* Apply default antenna delay value. See NOTE 2 below. */
	dwt_setrxantennadelay(RX_ANT_DLY);
	dwt_settxantennadelay(TX_ANT_DLY);

	/* Next can enable TX/RX states output on GPIOs 5 and 6 to help debug, and also TX/RX LEDs
	 * Note, in real low power applications the LEDs should not be used. */
	dwt_setlnapamode(DWT_LNA_ENABLE | DWT_PA_ENABLE);

	/* Set 16-bit short address */
	uint16_t anchor_short_addr = GET_UINT16(anchor->short_addr[0],anchor->short_addr[1]);
	dwt_setaddress16(anchor_short_addr);

	/* Disable frame filtering to get any incoming BLINK frame */
	dwt_configureframefilter(DWT_FF_DISABLE,DWT_FF_DATA_EN);

}



void anchor_application_init(uint16_t anchorAddr, uint16_t *coordinates)
{
	anchorDevice.short_addr[0] = (uint8_t)anchorAddr;
	anchorDevice.short_addr[1] = (uint8_t)(anchorAddr >> 8);

	anchorDevice.loc_x = coordinates[0];
	anchorDevice.loc_y = coordinates[1];
	anchorDevice.loc_z = coordinates[2];

	anchor_uwb_init(&anchorDevice);

	listener_init(&anchorDevice);

	ss_twr_responder_init(&anchorDevice);

}




void anchor_application(uint16_t anchorAddr, uint16_t *coordinates)
{

	anchor_application_init(anchorAddr, coordinates);
	int ret = -1; // Return status of tasks.

	while(1) /*Infinite while loop */
	{
		if(ret == 0)
		{
			listener_reinit();
		}

		ret = listener(&anchorDevice);
		if (ret == 0)
		{
			ss_twr_responder_reinit(&anchorDevice);

			ss_twr_responder();
		}

	}
}

