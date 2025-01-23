/*
 * EKFLocalization.h
 *
 *  Created on: Dec 23, 2024
 *      Author: kavindu
 */

#ifndef EKFLOCALIZATION_H
#define EKFLOCALIZATION_H

#include <stdio.h>
#include <stdint.h>
#include <math.h>


// Structure to hold the EKF properties
typedef struct {
    double A[6][6];           // State transition matrix
    double R[6][6];           // Process noise covariance matrix
    double Q[1][1];           // Measurement noise covariance matrix
    double sigma_bar_t[6][6]; // Predicted state covariance matrix
    double mubar_t[6];        // Predicted state vector (mean)
} EKFLocalization;


// Anchor information Type Definitions
typedef struct {
	double anchor_x;
	double anchor_y;
	double anchor_z;
	double  distance;
} sensor_measurement;



// Function prototypes
void EKF_init(EKFLocalization *ekf, double A[6][6], double R[6][6], double Q[1][1], double mu_t0[6], double sigma_t0[6][6]);

void EKF_predict(EKFLocalization *ekf);

void EKF_update(EKFLocalization *ekf, sensor_measurement *zt);

#endif /* EKFLOCALIZATION_H */
