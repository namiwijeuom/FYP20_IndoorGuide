/*
 * ARKFLocalization.c
 *
 *  Created on: Jan 9, 2025
 *      Author: kavindu
 */

#include "ARKFLocalization.h"

// Initialize the ARKF instance
void ARKF_init(ARKFLocalization *arkf, double A[6][6], double R[6][6], double Q[1][1], double mu_t0[6], double sigma_t0[6][6], double b)
{
    for (int i = 0; i < 6; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            arkf->A[i][j] = A[i][j];
            arkf->R[i][j] = R[i][j];
        }
    }

    for (int i = 0; i < 6; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            arkf->sigma_bar_t[i][j] = sigma_t0[i][j];
        }
        arkf->mubar_t[i] = mu_t0[i];
    }

    arkf->Q[0][0] = Q[0][0];
    arkf->b = b;
}


// Prediction step of the ARKF
void ARKF_predict(ARKFLocalization *arkf)
{
    double mu_tm1[6];
    for (int i = 0; i < 6; i++)
    {
        mu_tm1[i] = arkf->mubar_t[i];
    }

    // Update the predicted state vector
    for (int i = 0; i < 6; i++)
    {
        arkf->mubar_t[i] = 0.0;
        for (int j = 0; j < 6; j++)
        {
            arkf->mubar_t[i] += arkf->A[i][j] * mu_tm1[j];
        }
    }

    double sigma_tm1[6][6];
    for (int i = 0; i < 6; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            sigma_tm1[i][j] = arkf->sigma_bar_t[i][j];
        }
    }

    // Update the predicted state covariance matrix
    for (int i = 0; i < 6; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            arkf->sigma_bar_t[i][j] = arkf->R[i][j];
            for (int k = 0; k < 6; k++)
            {
                arkf->sigma_bar_t[i][j] += arkf->A[i][k] * sigma_tm1[k][j];
            }
        }
    }
}


// Update step of the ARKF
void ARKF_update(ARKFLocalization *arkf, sensor_measurement *zt)
{
    double di = zt->distance;
    double xj = zt->anchor_x;
    double yj = zt->anchor_y;
    double zj = zt->anchor_z;
    double delta_x = arkf->mubar_t[0] - xj;
    double delta_y = arkf->mubar_t[1] - yj;
    double delta_z = arkf->mubar_t[2] - zj;

    double sqrt_q = sqrt(delta_x * delta_x + delta_y * delta_y + delta_z * delta_z);

    // Jacobian matrix: Ht
    double Ht[1][6] = {
        {delta_x / sqrt_q, delta_y / sqrt_q, delta_z / sqrt_q, 0.0, 0.0, 0.0}
    };

    // Variance of residual
    double D_k = arkf->Q[0][0];
    for (int i = 0; i < 6; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            D_k += Ht[0][i] * arkf->sigma_bar_t[i][j] * Ht[0][j];
        }
    }

    // Residual calculation and adaptive adjustment
    double dhat_i = sqrt_q;
    double residual = di - dhat_i;
    double abs_residual = fabs(residual);
    double sqrt_Dk = sqrt(D_k);

    double c = 1.0; // Correction coefficient
    if ((abs_residual > (3 * sqrt_Dk)) && (abs_residual <= (6 * sqrt_Dk)))
    {
        c = 1.0 - arkf->b * ((abs_residual / (3*sqrt_Dk)) - 1.0);
    }
    else if (abs_residual > (6 * sqrt_Dk))
    {
        c = 1.0 - arkf->b;
    }

    double adjusted_residual = c * residual;
    double Dk_star = c * c * D_k;

    // Kalman Gain
    double Kt[6];
    for (int i = 0; i < 6; i++)
    {
        Kt[i] = 0.0;
        for (int j = 0; j < 6; j++)
        {
            Kt[i] += arkf->sigma_bar_t[i][j] * Ht[0][j];
        }
        Kt[i] /= Dk_star;
    }

    // Update state vector
    for (int i = 0; i < 6; i++)
    {
        arkf->mubar_t[i] += Kt[i] * adjusted_residual;
    }

    // Update covariance matrix
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
                new_sigma_bar_t[i][j] += I_minus_KHt[i][k] * arkf->sigma_bar_t[k][j];
            }
        }
    }

    // Copy updated sigma_bar_t back to the struct
    for (int i = 0; i < 6; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            arkf->sigma_bar_t[i][j] = new_sigma_bar_t[i][j];
        }
    }

    // Force symmetry for the sigma_bar_t matrix
    for (int i = 0; i < 6; i++)
    {
        for (int j = i + 1; j < 6; j++)
        {
            double average = 0.5 * (arkf->sigma_bar_t[i][j] + arkf->sigma_bar_t[j][i]);
            arkf->sigma_bar_t[i][j] = average;
            arkf->sigma_bar_t[j][i] = average;
        }
    }
}
