/*
 * tag_app.h
 *
 *  Created on: Dec 29, 2024
 *      Author: kavindu
 */

#ifndef TAG_APP_H
#define TAG_APP_H

#include <stdint.h>

#include "../../UWB_tasks/Blink/blink.h"
#include "../../UWB_tasks/ss_twr_init/ss_twr_init.h"

#include "../../Common/common_defines.h"


#define MAX_NUM_OF_FETCHED_ANCHORS 4 

#define FRAME_TRANSMIT_TIME_MS        40  //In milliseconds

#define MAX_NUM_OF_TAGS 5       // Estimated maximum number of tags in the environment



/* Define the state estimation filter */
#define FILTER_ARKF

/* Common Defines */
#define NUM_OF_ANCHORS 4

#define TIME_STEP      0.5
#define TIME_STEP_MS   TIME_STEP * 1000



#if defined(FILTER_ARKF)

#include "../../Math_utils/ARKFLocalization.h"


/* ARKF Parameters */

#define TUNE_RT          0.5
#define TUNE_QT	         30
#define MODULATION_INDEX 0.8 

#else
	#error "FILTER_ARKF is not defined."

#endif /* Filter parameters initialization */

//Todo: Add below descriptions properly.

/**
 * @brief Brief description of the function.
 * @details (Optional) More detailed explanation of what the function does.
 *
 * @param[in] param1 Description of the first parameter.
 * @param[out] param2 Description of the second parameter (if modified).
 * @param[in,out] param3 Description if it's both input and output.
 * @return Description of the return value.
 * @retval Specific return values and their meaning.
 * @throws List of exceptions the function might throw.
 * @warning Important warnings about usage.
 * @note Additional notes.
 */
void tag_application_init(uint16_t tagAddr);



/**
 * @brief Brief description of the function.
 * @details (Optional) More detailed explanation of what the function does.
 *
 * @param[in] param1 Description of the first parameter.
 * @param[out] param2 Description of the second parameter (if modified).
 * @param[in,out] param3 Description if it's both input and output.
 * @return Description of the return value.
 * @retval Specific return values and their meaning.
 * @throws List of exceptions the function might throw.
 * @warning Important warnings about usage.
 * @note Additional notes.
 */
void tag_application(uint16_t tagAddr);


#endif /* TAG_APP_H */
