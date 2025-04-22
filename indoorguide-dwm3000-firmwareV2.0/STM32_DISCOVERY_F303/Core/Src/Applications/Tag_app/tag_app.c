/*
 * tag_app.c
 *
 *  Created on: Dec 23, 2024
 *      Author: kavindu
 */

#include <math.h>
#include <stdlib.h>
#include "tag_app.h"




/* START Common Variables */

static double measurements[NUM_OF_ANCHORS];     // Todo: need this or not ? Stores distance measurements
double current_location[2] = {0};               // Global variable to store current (x,y) location

char str_buffer[60];   // buffer to store printing texts

/* END Common Variables */

#if defined(FILTER_ARKF)

static sensor_measurement zt;

// Define state transition matrix A
double At[6][6] = {                     //Todo: instead of 6x6 , use STATE_DIM define
    {1, 0, 0, TIME_STEP, 0, 0},
    {0, 1, 0, 0, TIME_STEP, 0},
    {0, 0, 1, 0, 0, TIME_STEP},
    {0, 0, 0, 1, 0, 0},
    {0, 0, 0, 0, 1, 0},
    {0, 0, 0, 0, 0, 1}
};

// Define process noise covariance matrix Q
double Qt[1][1] = {
	{1*TUNE_QT}
};

// Define measurement noise covariance matrix R
double Rt[6][6] = {
    {1 * TUNE_RT, 0, 0, 0, 0, 0},
    {0, 1 * TUNE_RT, 0, 0, 0, 0},
    {0, 0, 1 * TUNE_RT, 0, 0, 0},
    {0, 0, 0, 1 * TUNE_RT, 0, 0},
    {0, 0, 0, 0, 1 * TUNE_RT, 0},
    {0, 0, 0, 0, 0, 1 * TUNE_RT}
};


// Define initial state vector (mu_tm1)
double mu_t0[6] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0};  // [x, y, vx, vy]

// Define initial covariance matrix (sigma_tm1)
double sigma_t0[6][6] = {
    {1.0, 0.0, 0.0, 0.0, 0.0, 0.0},
    {0.0, 1.0, 0.0, 0.0, 0.0, 0.0},
    {0.0, 0.0, 1.0, 0.0, 0.0, 0.0},
    {0.0, 0.0, 0.0, 1.0, 0.0, 0.0},
    {0.0, 0.0, 0.0, 0.0, 1.0, 0.0},
    {0.0, 0.0, 0.0, 0.0, 0.0, 1.0}
};


#else
	#error "FILTER_ARKF is not defined."
#endif /* Filter variable initialization */


/* Ekf Localization Object */
ARKFLocalization arkf;



//void tag_app(void)


//#elif defined(FILTER_ARKF)
//
//	ARKF_predict(&arkf);                      // ARKF prediction stage
//
//	for (int i = 0; i < NUM_OF_ANCHORS; i++)  // ARKF update stage
//	{
//		if (measurements[i] >= 0)             // Distance should be available (not -1)
//		{
//			Zt.distance = measurements[i] - 0.4;
//			Zt.anchor_x = anchor_xy[i][0];
//			Zt.anchor_y = anchor_xy[i][1];
//			Zt.anchor_z = anchor_xy[i][2];
//
//			ARKF_update(&arkf,&Zt);
//		}
//
//	}
//	current_location[0] = arkf.mubar_t[0];
//	current_location[1] = arkf.mubar_t[1];
//
//	memset(buffer,0,sizeof(buffer));
//	sprintf(buffer,"Current Location-ARKF : %.2f X , %.2f Y , %.2f Z",
//					  arkf.mubar_t[0],arkf.mubar_t[1],arkf.mubar_t[2]);
//	test_run_info((unsigned char*)buffer);
//
//#elif defined(FILTER_MULTILATERATION)
//
//	multilateration(anchor_xy,measurements,4,multilateration_xy);
//
//	if (!isnan(multilateration_xy[0]))
//	{
//		current_location[0] = multilateration_xy[0];
//		current_location[1] = multilateration_xy[1];
//	}
//
//#else
////
//#endif
//
//	return;
//}


extern void test_run_info(unsigned char *data);


extern dwt_config_t config_options;

/* Values for the PG_DELAY and TX_POWER registers reflect the bandwidth and power of the spectrum at the current
 * temperature. These values can be calibrated prior to taking reference measurements. See NOTE 2 below. */
extern dwt_txconfig_t txconfig_options;



taginfo_t tagDevice;

fetchedanchor_t already_fe_anchors; // Stores the addresses of already fetched anchors during a Time step.


/* Private function prototypes Begin */
static int is_anchor_valid(fetchedanchor_t *fetched_anchors, uint16_t new_addr);

static void clear_fetched_anchors(fetchedanchor_t *fetched_anchors);

static void random_init(void);

static uint32_t get_random_integer(uint32_t k);
/* Private function prototypes End */



void tag_uwb_init(taginfo_t *tag)
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

	/* Configure DW IC. See NOTE 2 below. */
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

	/* Set Tag device 16bit short address */
	uint16_t tag_short_addr = (tag->short_addr[0] | tag->short_addr[1] << 8); //Todo: use Macro GET_UINT16
	dwt_setaddress16(tag_short_addr);

}


/* Tag application initialization */
void tag_application_init(uint16_t tagAddr)
{
	tagDevice.short_addr[0] = (uint8_t)tagAddr;
	tagDevice.short_addr[1] = (uint8_t)(tagAddr >> 8);

	for(uint8_t i = 0; i < MAX_NUM_OF_FETCHED_ANCHORS; i++)
	{
		already_fe_anchors.fetched_addr[i] = 0;
	}
	already_fe_anchors.fetched_count = 0;


	tag_uwb_init(&tagDevice);

	blink_init(&tagDevice);

	ss_twr_initiator_init(&tagDevice);

	random_init();

	ARKF_init(&arkf, At, Rt, Qt, mu_t0, sigma_t0, MODULATION_INDEX);

}




void tag_application(uint16_t tagAddr)
{
	tag_application_init(tagAddr);
	int ret = 0; // Return status of tasks.

	while(1) /* Infinite while loop */
	{
		ret = 0;

		ARKF_predict(&arkf); //Predict step of ARKF

		uint32_t step_start_time = HAL_GetTick();

		while(((HAL_GetTick() - step_start_time) < TIME_STEP_MS) && (already_fe_anchors.fetched_count < MAX_NUM_OF_FETCHED_ANCHORS))
		{
			if(ret == 0)
			{
				blink_reinit(&already_fe_anchors);
			}

			ret = blink(&tagDevice);

			if(ret == 0)
			{
				uint16_t new_anchor = GET_UINT16(tagDevice.current_anchor.short_addr[0],tagDevice.current_anchor.short_addr[1]);

				if(is_anchor_valid(&already_fe_anchors, new_anchor) == 0)
				{
					already_fe_anchors.fetched_count++;
					already_fe_anchors.fetched_addr[already_fe_anchors.fetched_count-1] = new_anchor;

					ss_twr_initiator_reinit(&tagDevice);

					ss_twr_initiator(&tagDevice);

					zt.distance = (tagDevice.distance)/100.0;             // In meters.
					zt.anchor_x = (tagDevice.current_anchor.loc_x)/100.0;
					zt.anchor_y = (tagDevice.current_anchor.loc_y)/100.0;
					zt.anchor_z = (tagDevice.current_anchor.loc_z)/100.0;

					ARKF_update(&arkf, &zt);
				}


			}
			else
			{
				uint32_t r = get_random_integer(MAX_NUM_OF_TAGS);
				HAL_Delay(FRAME_TRANSMIT_TIME_MS * r);           // Radome backoff time delay before next BLINK
			}


		}

		clear_fetched_anchors(&already_fe_anchors);

		memset(str_buffer,0,sizeof(str_buffer));
		snprintf(str_buffer, sizeof(str_buffer), "{\"X\":\"%.2f\",\"Y\":\"%.2f\"}",arkf.mubar_t[0],arkf.mubar_t[1]);
		test_run_info(str_buffer);

		uint32_t step_stop_time = HAL_GetTick();  //Todo: Do this using simple while do nothing while loop.
		int delay_time = TIME_STEP_MS - (step_stop_time - step_start_time);

		if(delay_time > 0)
		{
			HAL_Delay(delay_time);
		}


	}

}



/* Private function definitions Begin */

static int is_anchor_valid(fetchedanchor_t *fetched_anchors, uint16_t new_addr)
{

    if (fetched_anchors->fetched_count >= MAX_NUM_OF_FETCHED_ANCHORS)
    {
        return -1;
    }

    // Check if new_addr exists in fetched_addr
    for (uint8_t i = 0; i < fetched_anchors->fetched_count; i++)
    {
        if (fetched_anchors->fetched_addr[i] == new_addr)
        {
            return -1;
        }
    }

    return 0;
}



static void clear_fetched_anchors(fetchedanchor_t *fetched_anchors)
{
	for(uint8_t i = 0; i < fetched_anchors->fetched_count; i++)
	{
		fetched_anchors->fetched_addr[i] = 0;
	}
	fetched_anchors->fetched_count = 0;
}



static void random_init(void)
{
    srand(HAL_GetTick());  // Use system tick as seed for randomness
}


static uint32_t get_random_integer(uint32_t k)
{
    return (rand() % (k + 1));  // Generate random number between 0 and k
}

/* Private function definitions End */












