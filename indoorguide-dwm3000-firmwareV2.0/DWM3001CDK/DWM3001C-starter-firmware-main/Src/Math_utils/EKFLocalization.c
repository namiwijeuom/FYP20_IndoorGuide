/*
 * EKFLocalization.c
 *
 *  Created on: Dec 23, 2024
 *      Author: kavindu
 */


#include "EKFLocalization.h"

// Initialize the EKF instance
void EKF_init(EKFLocalization *ekf, double A[6][6], double R[6][6], double Q[1][1], double mu_t0[6], double sigma_t0[6][6])
{

    for (int i = 0; i < 6; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            ekf->A[i][j] = A[i][j];
            ekf->R[i][j] = R[i][j];
            //ekf->sigma_bar_t[i][j] = 0.0; // Initialize to zero
        }
        //ekf->mubar_t[i] = 0.0; // Initialize to zero
    }


    for (int i = 0; i < 6; i++)
    {
    	for (int j = 0; j < 6; j++)
    	{
    		ekf->sigma_bar_t[i][j] = sigma_t0[i][j];
    	}
    	ekf->mubar_t[i] = mu_t0[i];
    }

    ekf->Q[0][0] = Q[0][0];
}




// Prediction step of the EKF
void EKF_predict(EKFLocalization *ekf)
{
	double mu_tm1[6];                // Matrix to hold the current state
	for (int i = 0; i < 6; i++)
	{
		mu_tm1[i] = ekf->mubar_t[i]; // Use the current state as input
	}
    // Update the predicted state vector: mubar_t = A * mu_tm1
    for (int i = 0; i < 6; i++)
    {
        ekf->mubar_t[i] = 0.0;
        for (int j = 0; j < 6; j++)
        {
            ekf->mubar_t[i] += ekf->A[i][j] * mu_tm1[j];
        }
    }


    double sigma_tm1[6][6];          // Matrix to hold the current state covariance
	for (int i = 0; i < 6; i++)
	{
		for (int j = 0; j < 6; j++)
		{
			sigma_tm1[i][j] = ekf->sigma_bar_t[i][j]; // Use the current covariance as input
		}
	}

    // Update the predicted state covariance matrix: sigma_bar_t = A * sigma_tm1 * A' + R
    for (int i = 0; i < 6; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            ekf->sigma_bar_t[i][j] = ekf->R[i][j]; // Start with R
            for (int k = 0; k < 6; k++)
            {
                ekf->sigma_bar_t[i][j] += ekf->A[i][k] * sigma_tm1[k][j];
            }
        }
    }
}




// Update step of the EKF
void EKF_update(EKFLocalization *ekf, sensor_measurement *zt)
{
    double di = zt->distance;
    double xj = zt->anchor_x;
    double yj = zt->anchor_y;
    double zj = zt->anchor_z;
    double delta_x = ekf->mubar_t[0] - xj;
    double delta_y = ekf->mubar_t[1] - yj;
    double delta_z = ekf->mubar_t[2] - zj;
    double delta[3] = {delta_x, delta_y, delta_z};        //TODO: delta[3] is not needed - remove

    double sqrt_q = sqrt(delta_x * delta_x + delta_y * delta_y + delta_z * delta_z);

    // Jacobian matrix: Ht
    double Ht[1][6] = {
        {delta_x / sqrt_q, delta_y / sqrt_q, delta_z / sqrt_q, 0.0, 0.0, 0.0}
    };

    // Kalman Gain: Kt
//	double S = Ht[0][0] * ekf->sigma_bar_t[0][0] * Ht[0][0] +   // TODO: This is implemented assuming
//			   Ht[0][1] * ekf->sigma_bar_t[1][1] * Ht[0][1] +   // sigma_bar is diagonal -> check the accuracy
//			   Ht[0][2] * ekf->sigma_bar_t[2][2] * Ht[0][2] +   // Otherwise have to the use full computation
//			   ekf->Q[0][0];
    double S = ekf->Q[0][0];
    for (int i = 0; i < 6; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            S += Ht[0][i] * ekf->sigma_bar_t[i][j] * Ht[0][j];
        }
    }


	double Kt[6];
	for (int i = 0; i < 6; i++)
	{
		Kt[i] = 0.0;
		for (int j = 0; j < 3; j++)
		{                   // only iterate upto 3, since last three elements of Jacobian are zeros.
			Kt[i] += ekf->sigma_bar_t[i][j] * Ht[0][j];
		}
		Kt[i] /= S;
	}

	// Measurement residual: (di - dhat_i)
	double dhat_i = sqrt_q;
	double residual = di - dhat_i;

	// Update state vector: mubar_t = mubar_t + Kt * residual
	for (int i = 0; i < 6; i++)
	{
		ekf->mubar_t[i] += Kt[i] * residual;
	}

	// Update covariance matrix: sigma_bar_t = (I - Kt * Ht) * sigma_bar_t
	double I_minus_KHt[6][6];
	for (int i = 0; i < 6; i++)
	{
		for (int j = 0; j < 6; j++)
		{
			I_minus_KHt[i][j] = -Kt[i] * Ht[0][j];
			if (i == j)
			{
				I_minus_KHt[i][j] += 1.0;
			}
		}
	}

	double new_sigma_bar_t[6][6];
	for (int i = 0; i < 6; i++)
	{
		for (int j = 0; j < 6; j++)
		{
			new_sigma_bar_t[i][j] = 0.0;
			for (int k = 0; k < 6; k++)
			{
				new_sigma_bar_t[i][j] += I_minus_KHt[i][k] * ekf->sigma_bar_t[k][j];
			}
		}
	}

	// Copy updated sigma_bar_t back to the struct
	for (int i = 0; i < 6; i++)
	{
		for (int j = 0; j < 6; j++)
		{
			ekf->sigma_bar_t[i][j] = new_sigma_bar_t[i][j];
		}
	}

	//TODO:Add divergence corrections steps
	// Force symmetry for the ekf->sigma_bar_t matrix ,  (sigma = (sigma+sigma')/2)
	for (int i = 0; i < 6; i++)
	{
	    for (int j = i + 1; j < 6; j++)
	    {  // Only traverse the upper triangle
	        double average = 0.5 * (ekf->sigma_bar_t[i][j] + ekf->sigma_bar_t[j][i]);
	        ekf->sigma_bar_t[i][j] = average;
	        ekf->sigma_bar_t[j][i] = average;
	    }
	}
}



