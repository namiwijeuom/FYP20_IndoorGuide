/*
 * EKFLocalization.h
 *
 *  Created on: Dec 23, 2024
 *      Author: kavindu
 */

#ifndef EKFLOCALIZATION_H
#define EKFLOCALIZATION_H

#include <stdio.h>
#include <math.h>


// Structure to hold the EKF properties
typedef struct {
    double A[4][4];          // State transition matrix
    double R[4][4];          // Process noise covariance matrix
    double Q[1][1];          // Measurement noise covariance matrix
    double sigma_bar_t[4][4]; // Predicted state covariance matrix
    double mubar_t[4];       // Predicted state vector (mean)
} EKFLocalization;



// Function prototypes
void EKF_init(EKFLocalization *ekf, double A[4][4], double R[4][4], double Q[1][1]);

void EKF_predict(EKFLocalization *ekf, double mu_tm1[4], double sigma_tm1[4][4]);

void EKF_update(EKFLocalization *ekf, double zt[3]);

#endif /* EKFLOCALIZATION_H */
