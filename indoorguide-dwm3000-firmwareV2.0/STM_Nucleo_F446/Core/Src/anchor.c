/*
 * anchor.c
 *
 *  Created on: Dec 20, 2024
 *      Author: User
 */

#include "deca_probe_interface.h"
#include <deca_device_api.h>
#include <deca_spi.h>
//#include <example_selection.h>
#include <port.h>
#include <shared_defines.h>
#include <shared_functions.h>

extern void test_run_info(unsigned char *data);

/* Example application name */
#define APP_NAME "SS TWR RESP v1.0"

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

/* Default antenna delay values for 64 MHz PRF. See NOTE 2 below. */
#define TX_ANT_DLY 16385
#define RX_ANT_DLY 16385

/* Frames used in the ranging process. See NOTE 3 below. */
static uint8_t rng_cfg_msg[] = {0xC5, 0, 'R', 'N', 'C', 'F', 'G', 'A', '0', '0'};

#define FRAME_LENGTH (sizeof(rng_cfg_msg) + FCS_LEN) // The real length that is going to be transmitted

static uint8_t rx_poll_msg[] = { 0x41, 0x88, 0, 0xCA, 0xDE, 'W', 'A', 'V', 'E', 0xE0, 0, 0 };
static uint8_t tx_resp_msg[] = { 0x41, 0x88, 0, 0xCA, 0xDE, 'V', 'E', 'W', 'A', 0xE1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
/* Length of the common part of the message (up to and including the function code, see NOTE 3 below). */
#define ALL_MSG_COMMON_LEN 10
/* Index to access some of the fields in the frames involved in the process. */
#define ALL_MSG_SN_IDX          2
#define RNG_CFG_MSG_SN_IDX      1
#define RESP_MSG_POLL_RX_TS_IDX 10
#define RESP_MSG_RESP_TX_TS_IDX 14
#define RESP_MSG_TS_LEN         4
/* Frame sequence number, incremented after each transmission. */
static uint8_t frame_seq_nb = 0;

/* Buffer to store received messages.
 * Its size is adjusted to longest frame that this example code is supposed to handle. */
#define RX_BUF_LEN 12 // Must be less than FRAME_LEN_MAX_EX
static uint8_t rx_buffer[RX_BUF_LEN];

/* Hold copy of status register state here for reference so that it can be examined at a debug breakpoint. */
static uint32_t status_reg = 0;

/* Delay between frames, in UWB microseconds. See NOTE 1 below. */
#define POLL_RX_TO_RESP_TX_DLY_UUS 650

/* Timestamps of frames transmission/reception. */
static uint64_t poll_rx_ts;
static uint64_t resp_tx_ts;

/* Values for the PG_DELAY and TX_POWER registers reflect the bandwidth and power of the spectrum at the current
 * temperature. These values can be calibrated prior to taking reference measurements. See NOTE 5 below. */
extern dwt_txconfig_t txconfig_options;













void anchor_init(uint8_t anchorID)
{
	/* Display application name on LCD. */
	test_run_info((unsigned char *)APP_NAME);

	/* Configure SPI rate, DW3000 supports up to 36 MHz */
	port_set_dw_ic_spi_fastrate();

	/* Reset and initialize DW chip. */
	reset_DWIC(); /* Target specific drive of RSTn line into DW3000 low for a period. */

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

	/* Configure DW IC. See NOTE 13 below. */
	/* if the dwt_configure returns DWT_ERROR either the PLL or RX calibration has failed the host should reset the device */
	if (dwt_configure(&config))
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

}



void ranging_config_send(void)
{

	/* Write frame data to DW IC and prepare transmission. See NOTE 3 below.*/
	dwt_writetxdata(FRAME_LENGTH - FCS_LEN,rng_cfg_msg, 0); /* Zero offset in TX buffer. */

	/* In this example since the length of the transmitted frame does not change,
	 * nor the other parameters of the dwt_writetxfctrl function, the
	 * dwt_writetxfctrl call could be outside the main while(1) loop.
	 */
	dwt_writetxfctrl(FRAME_LENGTH, 0, 0); /* Zero offset in TX buffer, no ranging. */

	/* Start transmission. */
	dwt_starttx(DWT_START_TX_IMMEDIATE);
	/* Poll DW IC until TX frame sent event set. See NOTE 4 below.
	 * STATUS register is 4 bytes long but, as the event we are looking
	 * at is in the first byte of the register, we can use this simplest
	 * API function to access it.*/
	waitforsysstatus(NULL, NULL, DWT_INT_TXFRS_BIT_MASK, 0);

	/* Clear TX frame sent event. */
	dwt_writesysstatuslo(DWT_INT_TXFRS_BIT_MASK);

	test_run_info((unsigned char *)"TX Frame Sent");

	/* Execute a delay between transmissions. */
	//Sleep(500);

	/* Increment the blink frame sequence number (modulo 256). */
	//rng_cfg_msg[RNG_CFG_MSG_SN_IDX]++;

}


void anchor_process_start(uint8_t anchorID)
{
	anchor_init(anchorID);

	while(1)
	{

		//ranging_config_send();
		dwt_rxenable(DWT_START_RX_IMMEDIATE);

		/* Poll for reception of a frame or error/timeout. See NOTE 6 below. */
		waitforsysstatus(&status_reg, NULL, (DWT_INT_RXFCG_BIT_MASK | SYS_STATUS_ALL_RX_ERR), 0);

		if (status_reg & DWT_INT_RXFCG_BIT_MASK)
		{
			uint16_t frame_len;

			/* Clear good RX frame event in the DW IC status register. */
			dwt_writesysstatuslo(DWT_INT_RXFCG_BIT_MASK);

			/* A frame has been received, read it into the local buffer. */
			frame_len = dwt_getframelength();
			if (frame_len <= sizeof(rx_buffer))
			{
				dwt_readrxdata(rx_buffer, frame_len-FCS_LEN, 0);
				test_run_info((unsigned char*)&rx_buffer[2]);
				ranging_config_send();
			}

		}
		else
		{
			/* Clear RX error events in the DW IC status register. */
			dwt_writesysstatuslo(SYS_STATUS_ALL_RX_ERR);
			test_run_info("rx error - anchor");
		}
		Sleep(100);


	}
}








