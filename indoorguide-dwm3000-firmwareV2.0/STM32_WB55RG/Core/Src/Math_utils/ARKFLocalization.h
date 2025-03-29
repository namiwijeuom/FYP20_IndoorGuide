/*
 * ARKFLocalization.h
 *
 *  Created on: Jan 10, 2025
 *      Author: kavindu
 */

#ifndef ARKFLOCALIZATION_H
#define ARKFLOCALIZATION_H

#include <stdio.h>
#include <stdint.h>
#include <math.h>


#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif


// Structure to hold the ARKF properties
typedef struct {
    double A[6][6];           // State transition matrix
    double R[6][6];           // Process noise covariance matrix
    double Q[1][1];           // Measurement noise covariance matrix
    double sigma_bar_t[6][6]; // Predicted state covariance matrix
    double mubar_t[6];        // Predicted state vector (mean)
    double b;                 // Modulation index for adaptive adjustment
} ARKFLocalization;

// Anchor information Type Definitions
typedef struct {
    double anchor_x;
    double anchor_y;
    double anchor_z;
    double distance;
} sensor_measurement;


// Function prototypes
void ARKF_init(ARKFLocalization *arkf, double A[6][6], double R[6][6], double Q[1][1], double mu_t0[6], double sigma_t0[6][6], double b);

void ARKF_predict(ARKFLocalization *arkf);

void ARKF_update(ARKFLocalization *arkf, sensor_measurement *zt);

#endif /* ARKFLOCALIZATION_H */
