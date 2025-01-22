/*
 * tag.c
 *
 *  Created on: Dec 20, 2024
 *      Author: User
 *
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
#define APP_NAME "TAG_APP		"

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
    DWT_STS_MODE_OFF, /* No STS mode enabled (STS Mode 0). */
    DWT_STS_LEN_64,   /* STS length, see allowed values in Enum dwt_sts_lengths_e */
    DWT_PDOA_M0       /* PDOA mode off */
};

/* The frame sent in this example is an 802.15.4e standard blink. It is a 12-byte frame composed of the following fields:
 *     - byte 0: frame type (0xC5 for a blink).
 *     - byte 1: sequence number, incremented for each new frame.
 *     - byte 2 -> 9: device ID, see NOTE 1 below.
 */
//static uint8_t tx_msg[] = { 0xC5, 0, 'D', 'E', 'C', 'A', 'W', 'A', 'V', 'E' };
static uint8_t tx_msg[] = {0xC5, 0, 'B', 'L', 'I', 'N', 'K', 'T', '0', '1'};
/* Index to access to sequence number of the blink frame in the tx_msg array. */
#define BLINK_FRAME_SN_IDX 1

#define FRAME_LENGTH (sizeof(tx_msg) + FCS_LEN) // The real length that is going to be transmitted

/* Inter-frame delay period, in milliseconds. */
//#define TX_DELAY_MS 500






#define RNG_DELAY_MS 1000

/* Default antenna delay values for 64 MHz PRF. See NOTE 2 below. */
#define TX_ANT_DLY 16385
#define RX_ANT_DLY 16385

/* Frames used in the ranging process. See NOTE 3 below. */
static uint8_t tx_poll_msg[] = { 0x41, 0x88, 0, 0xCA, 0xDE, 'W', 'A', 'V', 'E', 0xE0, 0, 0 };
static uint8_t rx_resp_msg[] = { 0x41, 0x88, 0, 0xCA, 0xDE, 'V', 'E', 'W', 'A', 0xE1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
/* Length of the common part of the message (up to and including the function code, see NOTE 3 below). */
#define ALL_MSG_COMMON_LEN 10
/* Indexes to access some of the fields in the frames defined above. */
#define ALL_MSG_SN_IDX          2
#define RESP_MSG_POLL_RX_TS_IDX 10
#define RESP_MSG_RESP_TX_TS_IDX 14
#define RESP_MSG_TS_LEN         4
/* Frame sequence number, incremented after each transmission. */
static uint8_t frame_seq_nb = 0;

/* Buffer to store received response message.
 * Its size is adjusted to longest frame that this example code is supposed to handle. */
#define RX_BUF_LEN 20
static uint8_t rx_buffer[RX_BUF_LEN];

/* Hold copy of status register state here for reference so that it can be examined at a debug breakpoint. */
static uint32_t status_reg = 0;
static uint8_t frame_len = 0 ;

/* Delay between frames, in UWB microseconds. See NOTE 1 below. */
#define POLL_TX_TO_RESP_RX_DLY_UUS 240
/* Receive response timeout. See NOTE 5 below. */
#define RESP_RX_TIMEOUT_UUS 4000  //400

/* Hold copies of computed time of flight and distance here for reference so that it can be examined at a debug breakpoint. */
static double tof;
static double distance;








/* Values for the PG_DELAY and TX_POWER registers reflect the bandwidth and power of the spectrum at the current
 * temperature. These values can be calibrated prior to taking reference measurements. See NOTE 2 below. */
extern dwt_txconfig_t txconfig_options;



void tag_init(uint8_t tagID)
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

	/* Set expected response's delay and timeout. See NOTE 1 and 5 below.
	 * As this example only handles one incoming frame with always the same delay and timeout, those values can be set here once for all. */
	//dwt_setrxaftertxdelay(POLL_TX_TO_RESP_RX_DLY_UUS);
	dwt_setrxtimeout(RESP_RX_TIMEOUT_UUS);

	/* Next can enable TX/RX states output on GPIOs 5 and 6 to help debug, and also TX/RX LEDs
	 * Note, in real low power applications the LEDs should not be used. */
	dwt_setlnapamode(DWT_LNA_ENABLE | DWT_PA_ENABLE);
}




void blink_send(void)
{
	dwt_writetxdata(FRAME_LENGTH - FCS_LEN, tx_msg, 0); /* Zero offset in TX buffer. */

	/* In this example since the length of the transmitted frame does not change,
	 * nor the other parameters of the dwt_writetxfctrl function, the
	 * dwt_writetxfctrl call could be outside the main while(1) loop.
	 */
	dwt_writetxfctrl(FRAME_LENGTH, 0, 0); /* Zero offset in TX buffer, no ranging. */

	/* Start transmission with expecting a ranging config from an anchor*/
	dwt_starttx(DWT_START_TX_IMMEDIATE | DWT_RESPONSE_EXPECTED);
	/* Poll DW IC until TX frame sent event set. See NOTE 4 below.
	 * STATUS register is 4 bytes long but, as the event we are looking
	 * at is in the first byte of the register, we can use this simplest
	 * API function to access it.*/
	waitforsysstatus(NULL, NULL, DWT_INT_TXFRS_BIT_MASK, 0);

	/* Clear TX frame sent event. */
	dwt_writesysstatuslo(DWT_INT_TXFRS_BIT_MASK);

	test_run_info((unsigned char *)"TX Frame Sent");

	/* Increment the blink frame sequence number (modulo 256). */
	//tx_msg[BLINK_FRAME_SN_IDX]++;
}


void send_initiator_poll_msg()
{
	//
}


void tag_process_start(uint8_t tagID)
{
	tag_init(tagID);


	while(1)
	{
		test_run_info("while loop");
		blink_send();
		//dwt_rxenable(DWT_START_RX_IMMEDIATE);
		//memset(rx_buffer, 0, sizeof(rx_buffer));
		waitforsysstatus(&status_reg, NULL, (DWT_INT_RXFCG_BIT_MASK | SYS_STATUS_ALL_RX_ERR | DWT_INT_RXFTO_BIT_MASK), 0);

		if (status_reg & DWT_INT_RXFCG_BIT_MASK)
		{
			/* A frame has been received, copy it to our local buffer. */
			frame_len = dwt_getframelength();
			if (frame_len <= FRAME_LEN_MAX)
			{
				dwt_readrxdata(rx_buffer, frame_len - FCS_LEN, 0); /* No need to read the FCS/CRC. */
			}

			/* Clear good RX frame event in the DW IC status register. */
			dwt_writesysstatuslo(DWT_INT_RXFCG_BIT_MASK);

			test_run_info((unsigned char *)"Frame Received");
			test_run_info((unsigned char *)&rx_buffer[2]);
		}
		else
		{
			/* Clear RX error events in the DW IC status register. */
			dwt_writesysstatuslo(SYS_STATUS_ALL_RX_ERR | DWT_INT_RXFTO_BIT_MASK);
			test_run_info("rx error - tag");
		}
		Sleep(100);


	}

}







