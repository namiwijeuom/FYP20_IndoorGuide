/*
 * PFLocalization.h
 *
 *  Created on: Jan 6, 2025
 *      Author: kavindu
 */

#ifndef PFLOCALIZATION_H
#define PFLOCALIZATION_H

#include <stdint.h>
#include <math.h>
#include <stdlib.h>
//#include <float.h>   // check whether this is needed or not?

/* Resampling Method */
#define RESAMPLE_SYSTEMATIC
//#define RESAMPLE_MULTINOMINAL



// Define constants
#define STATE_DIM 6        // State vector dimension: {x, y, v_x, v_y}
#define NUM_PARTICLES 200  // Number of particles
#define MEAS_DIM 1         // Measurement dimension: {{distance}}
#define ANCHOR_DIM 3       // Anchor dimension: {x, y} //Todo: No need this ?

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// Particle Filter structure
typedef struct {
    double particles[NUM_PARTICLES][STATE_DIM]; // Particle states
    double weights[NUM_PARTICLES];              // Particle weights
    double At[STATE_DIM][STATE_DIM];            // State transition model
    double Rt[STATE_DIM][STATE_DIM];            // Process noise covariance
    double Qt[MEAS_DIM][MEAS_DIM];              // Measurement noise covariance
    double Neff;                                // Number of effective samples
} PFLocalization;

/* Function prototypes */


/**
 * @brief This function initializes the particle filter with the given parameters.
 *
 * Sets up the particle filter's state transition matrix, process noise covariance,
 * measurement noise covariance, and initial state. It prepares the particle filter to start
 * estimating based on the provided system and measurement models.
 *
 * @param[out] pf - Pointer to the PFLocalization structure to be initialized.
 * @param[in]  At - State transition matrix (STATE_DIM x STATE_DIM).
 * @param[in]  Rt - Process noise covariance matrix (STATE_DIM x STATE_DIM).
 * @param[in]  Qt - Measurement noise covariance matrix (MEAS_DIM x MEAS_DIM).
 * @param[in]  init_state - Initial state vector (STATE_DIM).
 *
 * @return None.
 */
void PF_init(PFLocalization* pf, double At[STATE_DIM][STATE_DIM],
             double Rt[STATE_DIM][STATE_DIM],
             double Qt[MEAS_DIM][MEAS_DIM],
             double init_state[STATE_DIM]);


/**
 * @brief
 *
 * @param[out] pf
 *
 * @return None.
 */
void PF_predict(PFLocalization* pf);

void PF_update(PFLocalization* pf, double measurements[],
               double anchors[][ANCHOR_DIM], uint8_t num_anchors);

void PF_resample(PFLocalization* pf);

void PF_getEstimate(PFLocalization* pf, double* x, double* y);

#endif /* PFLOCALIZATION_H */

