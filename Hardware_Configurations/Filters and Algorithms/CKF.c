// CKF-based UWB Localization with Initial Multilateration
#include <stdio.h>
#include <math.h>
#include "multilateration.h" // Header file for multilateration function

#define DIM_STATE 3 // State vector dimension (x, y, z)
#define SIGMOID_LAMBDA 1.0
#define SIGMOID_MU 0.1
#define MAX_ITER 100 // Maximum iterations for convergence
#define TOLERANCE 1e-6 // Convergence tolerance
#define MAX_INNOVATION 2 // Maximum allowed innovation value
#define MAX_GAIN 2       // Maximum Kalman gain

// Sigmoid function for adaptive noise
float sigmoid_adaptive(float error) {
    return SIGMOID_LAMBDA * ((exp(SIGMOID_MU * error) - exp(-SIGMOID_MU * error)) /
                              (exp(SIGMOID_MU * error) + exp(-SIGMOID_MU * error)));
}

// CKF-based Localization Function
void CKF_Localization(double baseStations[][3], double *distances, int numStations, double *coords) {
    double state[DIM_STATE] = {coords[0], coords[1], coords[2]}; // Initial state from multilateration
    double P[DIM_STATE][DIM_STATE] = {              // Covariance matrix (identity matrix)
        {1.0, 0.0, 0.0},
        {0.0, 1.0, 0.0},
        {0.0, 0.0, 1.0}
    };

    double Q[DIM_STATE][DIM_STATE] = {              // Process noise covariance
        {0.01, 0.0, 0.0},
        {0.0, 0.01, 0.0},
        {0.0, 0.0, 0.01}
    };

    double R[numStations];                          // Measurement noise covariance
    for (int i = 0; i < numStations; i++) {
        R[i] = 0.02;
    }

    int iter = 0;
    double previous_error = 1e9;

    while (iter++ < MAX_ITER) {

        printf("Iteration: %d\n", iter);

        // State prediction
        //state[0] += state[3];
        //state[1] += state[3];
        //state[2] += state[3];

        printf("Predicted state: (%.2f, %.2f, %.2f)\n", state[0], state[1], state[2]);

        // Measurement update
        double innovation[numStations];
        double H[numStations][DIM_STATE];
        double S[numStations];
        double K[DIM_STATE];
        double residual = 0.0;

        for (int i = 0; i < numStations; i++) {
            double dx = state[0] - baseStations[i][0];
            double dy = state[1] - baseStations[i][1];
            double dz = state[2] - baseStations[i][2];
            double distance_sq = dx * dx + dy * dy + dz * dz;

            // Guard against invalid sqrt arguments
            if (distance_sq < 1e-9) {
                distance_sq = 1e-9;
            }

            double predicted_distance = sqrt(distance_sq);

            // Avoid division by zero for predicted_distance
            if (predicted_distance < 1e-9) {
                predicted_distance = 1e-9;
            }

            innovation[i] = distances[i] - predicted_distance;
            printf("Innovation: %.2f\n", innovation[i]);

            // Clip innovations to avoid divergence
            if (fabs(innovation[i]) > MAX_INNOVATION) {
                innovation[i] = copysign(MAX_INNOVATION, innovation[i]);
            }

            residual += innovation[i] * innovation[i];
            printf("Residual: %.2f\n", residual);

            // Observation matrix H
            H[i][0] = dx / predicted_distance;
            H[i][1] = dy / predicted_distance;
            H[i][2] = dz / predicted_distance;
            H[i][3] = 0;

            // Innovation covariance S
            S[i] = H[i][0] * P[0][0] * H[i][0] + H[i][1] * P[1][1] * H[i][1] + H[i][2] * P[2][2] * H[i][2] + R[i];

            // Guard against division by zero in S
            if (S[i] < 1e-9) {
                S[i] = 1e-9;
            }

            // Kalman gain
            K[0] = P[0][0] * H[i][0] / S[i];
            K[1] = P[1][1] * H[i][1] / S[i];
            K[2] = P[2][2] * H[i][2] / S[i];
            K[3] = 0;

            printf("Kalman gains: %.2f, %.2f, %.2f\n", K[0], K[1], K[2]);

            // Clip Kalman gains
            for (int k = 0; k < DIM_STATE; k++) {
                if (fabs(K[k]) > MAX_GAIN) {
                    K[k] = copysign(MAX_GAIN, K[k]);
                }
            }

            // Update state
            for (int k = 0; k < DIM_STATE; k++) {
                state[k] += K[k] * innovation[i];
            }

            // Update R dynamically using innovation
            R[i] = sigmoid_adaptive(fabs(innovation[i]));
        }

        // Check convergence
        if (fabs(residual - previous_error) < TOLERANCE) {
            break;
        }
        previous_error = residual;
    }

    // Output the final estimated position
    coords[0] = state[0];
    coords[1] = state[1];
    coords[2] = state[2];
}

int main() {
    double baseStations[4][3] = {
        {0.0, 0.0, 0.0},
        {10.0, 0.0, 0.0},
        {0.0, 10.0, 0.0},
        {0.0, 0.0, 10.0}
    };

    double distances[4] = {7.07, 7.07, 7.07, 7.07};
    double coords[3] = {0};

    // Get initial position using multilateration
    multilateration3D(baseStations, distances, 4, coords);
    printf("Initial coordinates from Multilateration: (%.2f, %.2f, %.2f)\n", coords[0], coords[1], coords[2]);

    if (isnan(coords[0]) || isnan(coords[1]) || isnan(coords[2])) {
        printf("Invalid input: coordinates could not be determined.\n");
        return 1;
    }

    // Refine the position using CKF
    CKF_Localization(baseStations, distances, 4, coords);

    printf("Refined coordinates: (%.2f, %.2f, %.2f)\n", coords[0], coords[1], coords[2]);

    return 0;
}
