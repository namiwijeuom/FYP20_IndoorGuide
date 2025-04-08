/*
 * PFLocalization.c
 *
 *  Created on: Jan 6, 2025
 *      Author: kavindu
 */

#include "PFLocalization.h"

/* Private function prototypes */
double rand_gaussian(double mean, double std_dev);



// Initialize Particle Filter
void PF_init(PFLocalization* pf,
			 double At[STATE_DIM][STATE_DIM],
             double Rt[STATE_DIM][STATE_DIM],
             double Qt[MEAS_DIM][MEAS_DIM],
             double init_state[STATE_DIM]) {

    // Set PF parameters
    for (int i = 0; i < STATE_DIM; i++)
    {
        for (int j = 0; j < STATE_DIM; j++)
        {
            pf->At[i][j] = At[i][j];
            pf->Rt[i][j] = Rt[i][j];
        }
    }

    for (int i = 0; i < MEAS_DIM; i++)
    {
        for (int j = 0; j < MEAS_DIM; j++)
        {
            pf->Qt[i][j] = Qt[i][j];
        }
    }

    // Initialize particles around the initial state
    double inv_num_particles = 1.0 / NUM_PARTICLES;

    for (int m = 0; m < NUM_PARTICLES; m++)
    {
        for (int i = 0; i < STATE_DIM; i++)
        {
            pf->particles[m][i] = init_state[i] + rand_gaussian(0.0, 1.0); // Add small noise
        }
        pf->weights[m] = inv_num_particles; // Uniform weight
    }
}


// Predict particles
void PF_predict(PFLocalization* pf)
{
	double noise[STATE_DIM];

    for (int m = 0; m < NUM_PARTICLES; m++)
    {
        for (int i = 0; i < STATE_DIM; i++)
        {
            noise[i] = rand_gaussian(0.0, pf->Rt[i][i]);
        }

        double new_state[STATE_DIM] = {0};

        for (int i = 0; i < STATE_DIM; i++)
        {
            for (int j = 0; j < STATE_DIM; j++)
            {
                new_state[i] += pf->At[i][j] * pf->particles[m][j];
            }
        }
        // Update the particle state with noise
		for (int i = 0; i < STATE_DIM; i++)
		{
			pf->particles[m][i] = new_state[i] + noise[i];
		}
    }
}



// Update particle weights
void PF_update(PFLocalization* pf,
			   double measurements[],
               double anchors[][ANCHOR_DIM],
			   uint8_t num_anchors) {

	double weight_sum = 0.0;
	double inv_Qt = 1.0 / pf->Qt[0][0];

    for (int m = 0; m < NUM_PARTICLES; m++)
    {
        double weight = 1.0;
        double log_weight = 0;

        for (int i = 0; i < num_anchors; i++)
        {
            if (measurements[i] >= 0)
            {
                double dx = pf->particles[m][0] - anchors[i][0];
                double dy = pf->particles[m][1] - anchors[i][1];
                double dz = pf->particles[m][2] - anchors[i][2];
                double estimated_distance = sqrt(dx * dx + dy * dy + dz * dz);
                double measurement_diff = measurements[i] - estimated_distance;
                //double log_weight = (-0.5 * (measurement_diff * measurement_diff) * inv_Qt);
                //double exp_weight = exp(log_weight);
                //weight *= exp_weight;
                log_weight += (-0.5 * (measurement_diff * measurement_diff) * inv_Qt);
            }
        }

        pf->weights[m] = exp(log_weight);
        //weight_sum += weight;
        weight_sum += pf->weights[m];
    }

    // Normalize weights
//    double weight_sum = 0.0;
//    for (int m = 0; m < NUM_PARTICLES; m++)
//    {
//        weight_sum += pf->weights[m];         //Todo: This part can be done just after pf->weights[m] = weight;
//    }
    double inv_weight_sum = 1.0 / weight_sum;

    for (int m = 0; m < NUM_PARTICLES; m++)
    {
        pf->weights[m] *= inv_weight_sum;
        pf->Neff += pf->weights[m] * pf->weights[m]; // Calculating effective sample size
    }
    pf->Neff = 1.0 / pf->Neff;
}



void PF_resample(PFLocalization* pf)
{
    double csw[NUM_PARTICLES]; // Cumulative sum of weights
    csw[0] = pf->weights[0];

    // Compute the cumulative sum of weights
    for (int m = 1; m < NUM_PARTICLES; m++)
    {
        csw[m] = csw[m - 1] + pf->weights[m];
    }

    double new_particles[NUM_PARTICLES][STATE_DIM];

#if defined(RESAMPLE_MULTINOMINAL)

    // Multinomial resampling
    for (int m = 0; m < NUM_PARTICLES; m++)
    {
        double r = (double)rand() / RAND_MAX; // Uniform random number [0, 1)
        int i = 0;

        // Find the particle corresponding to the random number
        while (i < NUM_PARTICLES - 1 && r > csw[i])
        {
            i++;
        }

        // Copy the selected particle
        for (int j = 0; j < STATE_DIM; j++)
        {
            new_particles[m][j] = pf->particles[i][j];
        }
    }

#elif defined(RESAMPLE_SYSTEMATIC)
    // Systematic resampling
	double r_step = 1.0 / NUM_PARTICLES; // Step size
	double r = ((double)rand() / RAND_MAX) * r_step; // Random offset in [0, r_step)
	int i = 0;

	for (int m = 0; m < NUM_PARTICLES; m++)
	{
		double target = r + m * r_step;

		// Find the particle corresponding to the target
		while (i < NUM_PARTICLES - 1 && target > csw[i])
		{
			i++;
		}

		// Copy the selected particle
		for (int j = 0; j < STATE_DIM; j++)
		{
			new_particles[m][j] = pf->particles[i][j];
		}
	}

#else
    //
#endif
    // Copy new_particles back to pf->particles
    for (int m = 0; m < NUM_PARTICLES; m++)
    {
        for (int j = 0; j < STATE_DIM; j++)
        {
            pf->particles[m][j] = new_particles[m][j];
        }
    }
}



// Get state estimate
void PF_getEstimate(PFLocalization* pf, double* x, double* y)
{
    double x_weighted = 0.0, y_weighted = 0.0;
    for (int m = 0; m < NUM_PARTICLES; m++)
    {
    	x_weighted += pf->particles[m][0] * pf->weights[m];
    	y_weighted += pf->particles[m][1] * pf->weights[m];
    }
    *x = x_weighted; // NUM_PARTICLES; //Todo: No need to divide by NUM_OF_PARTICLES
    *y = y_weighted; // NUM_PARTICLES;
}

/*
// Get state estimate using the particle with the highest weight
void PF_getEstimate(PFLocalization* pf, double* x, double* y)
{
    double max_weight = 0.0;
    int max_index = 0;

    // Find the particle with the highest weight
    for (int m = 0; m < NUM_PARTICLES; m++)
    {
        if (pf->weights[m] > max_weight)
        {
            max_weight = pf->weights[m];
            max_index = m;
        }
    }

    // Use the state of the particle with the highest weight
    *x = pf->particles[max_index][0];
    *y = pf->particles[max_index][1];
} */



// Helper function: Gaussian random number
double rand_gaussian(double mean, double std_dev)
{
    double u1 = (double)rand() / RAND_MAX;
    double u2 = (double)rand() / RAND_MAX;
    double z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * M_PI * u2);
    return z0 * std_dev + mean;
}



