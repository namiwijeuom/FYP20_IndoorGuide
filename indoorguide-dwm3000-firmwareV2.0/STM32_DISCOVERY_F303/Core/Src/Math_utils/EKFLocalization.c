/*
 * EKFLocalization.c
 *
 *  Created on: Dec 23, 2024
 *      Author: kavindu
 */


#include "EKFLocalization.h"

// Initialize the EKF instance
void EKF_init(EKFLocalization *ekf, double A[4][4], double R[4][4], double Q[1][1]) {
    // Copy matrices into the struct
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            ekf->A[i][j] = A[i][j];
            ekf->R[i][j] = R[i][j];
            ekf->sigma_bar_t[i][j] = 0.0; // Initialize to zero
        }
        ekf->mubar_t[i] = 0.0; // Initialize to zero
    }
    ekf->Q[0][0] = Q[0][0];
}





// Prediction step of the EKF
void EKF_predict(EKFLocalization *ekf, double mu_tm1[4], double sigma_tm1[4][4]) {
    // Update the predicted state vector: mubar_t = A * mu_tm1
    for (int i = 0; i < 4; i++) {
        ekf->mubar_t[i] = 0.0;
        for (int j = 0; j < 4; j++) {
            ekf->mubar_t[i] += ekf->A[i][j] * mu_tm1[j];
        }
    }

    // Update the predicted state covariance matrix: sigma_bar_t = A * sigma_tm1 * A' + R
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            ekf->sigma_bar_t[i][j] = ekf->R[i][j]; // Start with R
            for (int k = 0; k < 4; k++) {
                ekf->sigma_bar_t[i][j] += ekf->A[i][k] * sigma_tm1[k][j];
            }
        }
    }
}






// Update step of the EKF
void EKF_update(EKFLocalization *ekf, double zt[3]) {
    double di = zt[0];
    double xj = zt[1];
    double yj = zt[2];
    double delta_x = ekf->mubar_t[0] - xj;
    double delta_y = ekf->mubar_t[1] - yj;
    double delta[2] = {delta_x, delta_y};

    double sqrt_q = sqrt(delta_x * delta_x + delta_y * delta_y);

    // Jacobian matrix: Ht
    double Ht[1][4] = {
        {delta_x / sqrt_q, delta_y / sqrt_q, 0.0, 0.0}
    };

    // Kalman Gain: Kt
    double S = Ht[0][0] * ekf->sigma_bar_t[0][0] * Ht[0][0] +
               Ht[0][1] * ekf->sigma_bar_t[1][1] * Ht[0][1] +
               ekf->Q[0][0];

    double Kt[4];
    for (int i = 0; i < 4; i++) {
        Kt[i] = (ekf->sigma_bar_t[i][0] * Ht[0][0] +
                 ekf->sigma_bar_t[i][1] * Ht[0][1]) / S;
    }

    // Measurement residual: (di - dhat_i)
    double dhat_i = sqrt_q;
    double residual = di - dhat_i;

    // Update state vector: mubar_t = mubar_t + Kt * residual
    for (int i = 0; i < 4; i++) {
        ekf->mubar_t[i] += Kt[i] * residual;
    }

    // Update covariance matrix: sigma_bar_t = (I - Kt * Ht) * sigma_bar_t
    double I_minus_KHt[4][4];
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            I_minus_KHt[i][j] = -Kt[i] * Ht[0][j];
            if (i == j) {
                I_minus_KHt[i][j] += 1.0;
            }
        }
    }

    double new_sigma_bar_t[4][4];
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            new_sigma_bar_t[i][j] = 0.0;
            for (int k = 0; k < 4; k++) {
                new_sigma_bar_t[i][j] += I_minus_KHt[i][k] * ekf->sigma_bar_t[k][j];
            }
        }
    }

    // Copy updated sigma_bar_t back to the struct
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            ekf->sigma_bar_t[i][j] = new_sigma_bar_t[i][j];
        }
    }
}



