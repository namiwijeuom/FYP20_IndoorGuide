/*
 * tag_app.h
 *
 *  Created on: Dec 29, 2024
 *      Author: kavindu
 */

#ifndef TAG_APP_H
#define TAG_APP_H

/* Defined the state estimation filter */
//#define FILTER_EKF
//#define FILTER_PF
#define FILTER_ARKF
//#define FILTER_MULTILATERATION



/* Common Defines */
#define NUM_OF_ANCHORS 4

#define TIME_STEP      0.5
#define TIME_STEP_MS   TIME_STEP * 1000


/* Filter parameters initialization */
#if defined(FILTER_EKF)

#include "../../Math_utils/EKFLocalization.h"


/* EKF Parameters */

#define TUNE_RT        0.5
#define TUNE_QT	       30


#elif defined(FILTER_PF)

#include "../../Math_utils/PFLocalization.h"

/* PF Parameters */

#define TUNE_RT        0.1   /* RT 0.1 and QT 5 worked much better */
#define TUNE_QT	       5
#define RESAMPLING_THRESHOLD 0.1  // alpha value 0.5,0.1


#elif defined(FILTER_ARKF)

#include "../../Math_utils/ARKFLocalization.h"


/* ARKF Parameters */

#define TUNE_RT        0.5
#define TUNE_QT	       30
#define MODULATION_INDEX 0.8

#elif defined(FILTER_MULTILATERATION)

#include "../../Math_utils/multilateration.h"

#else
//
#endif /* Filter parameters initialization */


extern void test_run_info(unsigned char *data);


/* Function prototypes */
void tag_app_init(void);

void tag_app(void);




#endif /* TAG_APP_H */
