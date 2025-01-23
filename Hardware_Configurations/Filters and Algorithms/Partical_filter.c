#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define M 1000 // Number of particles
#define STATE_DIM 4
#define MEAS_DIM 2
#define TEST_STEPS 20 // Number of time steps for the test

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// Global variables for model matrices and noise parameters
double At[STATE_DIM][STATE_DIM] = {
    {1, 0.5, 0, 0},
    {0, 1,   0, 0},
    {0, 0,   1, 0.5},
    {0, 0,   0, 1}
};
double Rt[STATE_DIM][STATE_DIM] = {
    {0.2, 0, 0, 0},
    {0, 0.2, 0, 0},
    {0, 0, 0.2, 0},
    {0, 0, 0, 0.2}
};
double Qt[MEAS_DIM][MEAS_DIM] = {
    {10, 0},
    {0, 10}
};
double mu_zt[MEAS_DIM] = {0, 0};

// Function to multiply matrices
void mat_mult(double A[STATE_DIM][STATE_DIM], double x[STATE_DIM], double result[STATE_DIM]) {
    for (int i = 0; i < STATE_DIM; i++) {
        result[i] = 0;
        for (int j = 0; j < STATE_DIM; j++) {
            result[i] += A[i][j] * x[j];
        }
    }
}

// Function to generate random Gaussian noise
double gaussian_noise(double mean, double variance) {
    double U1 = rand() / (double)RAND_MAX;
    double U2 = rand() / (double)RAND_MAX;
    double Z0 = sqrt(-2.0 * log(U1)) * cos(2 * M_PI * U2);
    return Z0 * sqrt(variance) + mean;
}

// Particle filter function
void particle_filter(double Xtm1[M][STATE_DIM], double zt[MEAS_DIM], double Xt[M][STATE_DIM], double pt[MEAS_DIM]) {
    double W[M];          // Weights of particles
    double Xbar_t[M][STATE_DIM]; // Predicted particles
    double sumW = 0.0;

    // Remove mean from measurement
    for (int i = 0; i < MEAS_DIM; i++) {
        zt[i] -= mu_zt[i];
    }

    // Prediction and correction step
    for (int m = 0; m < M; m++) {
        double noise[STATE_DIM] = {0};
        for (int i = 0; i < STATE_DIM; i++) {
            noise[i] = gaussian_noise(0, Rt[i][i]);
        }

        // Prediction: xtm = At * Xtm1 + noise
        mat_mult(At, Xtm1[m], Xbar_t[m]);
        for (int i = 0; i < STATE_DIM; i++) {
            Xbar_t[m][i] += noise[i];
        }

        // Measurement: W(m) = mvnpdf(zt, particle, Qt)
        double particle[MEAS_DIM] = {Xbar_t[m][0], Xbar_t[m][2]};
        double diff[MEAS_DIM] = {zt[0] - particle[0], zt[1] - particle[1]};
        double likelihood = exp(-0.5 * (diff[0] * diff[0] / Qt[0][0] + diff[1] * diff[1] / Qt[1][1]));
        W[m] = likelihood;
        sumW += W[m];
    }

    // Normalize weights
    for (int m = 0; m < M; m++) {
        W[m] /= sumW;
    }

    // Resampling step
    double Neff = 0.0;
    for (int m = 0; m < M; m++) {
        Neff += W[m] * W[m];
    }
    Neff = 1.0 / Neff;

    if (Neff < 0.5 * M) {
        // Systematic resampling
        double cumsum[M];
        cumsum[0] = W[0];
        for (int m = 1; m < M; m++) {
            cumsum[m] = cumsum[m - 1] + W[m];
        }

        double step = 1.0 / M;
        double u = ((double)rand() / RAND_MAX) * step;
        int idx = 0;

        for (int m = 0; m < M; m++) {
            while (u > cumsum[idx]) {
                idx++;
            }
            for (int i = 0; i < STATE_DIM; i++) {
                Xt[m][i] = Xbar_t[idx][i];
            }
            u += step;
        }
    } else {
        // No resampling
        for (int m = 0; m < M; m++) {
            for (int i = 0; i < STATE_DIM; i++) {
                Xt[m][i] = Xbar_t[m][i];
            }
        }
    }

    // Compute final estimate
    double mean[STATE_DIM] = {0};
    for (int m = 0; m < M; m++) {
        for (int i = 0; i < STATE_DIM; i++) {
            mean[i] += Xt[m][i] * W[m];
        }
    }
    pt[0] = mean[0];
    pt[1] = mean[2];
}

// Simulate true state dynamics
void true_state(double *state, double dt) {
    state[0] += state[1] * dt; // x = x + vx * dt
    state[2] += state[3] * dt; // y = y + vy * dt
}

// Generate noisy measurement
void generate_measurement(double *true_state, double *measurement, double noise_std) {
    measurement[0] = true_state[0] + gaussian_noise(0, noise_std); // Noisy x
    measurement[1] = true_state[2] + gaussian_noise(0, noise_std); // Noisy y
}

int main() {
    srand(time(0));

    // Initialize true state [x, vx, y, vy]
    double state[STATE_DIM] = {0.0, 1.0, 0.0, 1.0}; // Start at (0, 0), moving diagonally
    double dt = 0.5;                                // Time step
    double noise_std = 1.0;                         // Measurement noise standard deviation

    // Initialize particle set
    double Xtm1[M][STATE_DIM];
    for (int m = 0; m < M; m++) {
        for (int i = 0; i < STATE_DIM; i++) {
            Xtm1[m][i] = gaussian_noise(0, 1);
        }
    }

    printf("Time Step\tTrue X\tTrue Y\tEstimated X\tEstimated Y\n");
    printf("-------------------------------------------------------------\n");

    // Run the test over multiple time steps
    for (int t = 0; t < TEST_STEPS; t++) {
        // Simulate true dynamics
        true_state(state, dt);

        // Generate measurement
        double zt[MEAS_DIM];
        generate_measurement(state, zt, noise_std);

        // Run particle filter
        double Xt[M][STATE_DIM];
        double pt[MEAS_DIM]; // Estimated state [x, y]
        particle_filter(Xtm1, zt, Xt, pt);

        // Update particles for next iteration
        for (int m = 0; m < M; m++) {
            for (int i = 0; i < STATE_DIM; i++) {
                Xtm1[m][i] = Xt[m][i];
            }
        }

        // Print results
        printf("%d\t\t%.2f\t%.2f\t%.2f\t\t%.2f\n", t + 1, state[0], state[2], pt[0], pt[1]);
    }

    return 0;
}
