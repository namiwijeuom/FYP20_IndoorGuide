#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#define MAX_STATIONS 100

void multilateration3D(double baseStations[][3], double *distances, int numStations, double *coords) {
    // Check if we have enough base stations for 3D multilateration
    if (numStations < 4) {
        coords[0] = NAN;
        coords[1] = NAN;
        coords[2] = NAN;
        return;
    }

    // Allocate matrices for the system of equations
    double A[MAX_STATIONS][3] = {0};
    double B[MAX_STATIONS] = {0};

    // Set up the system of equations
    for (int i = 1; i < numStations; i++) {
        A[i - 1][0] = 2 * (baseStations[i][0] - baseStations[0][0]);
        A[i - 1][1] = 2 * (baseStations[i][1] - baseStations[0][1]);
        A[i - 1][2] = 2 * (baseStations[i][2] - baseStations[0][2]);
        
        B[i - 1] = pow(distances[0], 2) - pow(distances[i], 2)
                 + pow(baseStations[i][0], 2) - pow(baseStations[0][0], 2)
                 + pow(baseStations[i][1], 2) - pow(baseStations[0][1], 2)
                 + pow(baseStations[i][2], 2) - pow(baseStations[0][2], 2);
    }

    // Solve the system using pseudo-inverse (A^T * A)^(-1) * A^T * B
    double At[3][MAX_STATIONS] = {0}; // Transpose of A
    double AtA[3][3] = {0};           // At * A
    double AtB[3] = {0};              // At * B
    double invAtA[3][3] = {0};        // Inverse of At * A

    // Calculate At (transpose of A)
    for (int i = 0; i < numStations - 1; i++) {
        for (int j = 0; j < 3; j++) {
            At[j][i] = A[i][j];
        }
    }

    // Calculate At * A
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            for (int k = 0; k < numStations - 1; k++) {
                AtA[i][j] += At[i][k] * A[k][j];
            }
        }
    }

    // Calculate At * B
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < numStations - 1; j++) {
            AtB[i] += At[i][j] * B[j];
        }
    }

    // Invert At * A (using a simplified formula for 3x3 matrix inversion)
    double det = AtA[0][0] * (AtA[1][1] * AtA[2][2] - AtA[1][2] * AtA[2][1])
               - AtA[0][1] * (AtA[1][0] * AtA[2][2] - AtA[1][2] * AtA[2][0])
               + AtA[0][2] * (AtA[1][0] * AtA[2][1] - AtA[1][1] * AtA[2][0]);

    if (fabs(det) < 1e-6) {
        coords[0] = NAN;
        coords[1] = NAN;
        coords[2] = NAN;
        return;
    }

    double invDet = 1.0 / det;

    invAtA[0][0] =  (AtA[1][1] * AtA[2][2] - AtA[1][2] * AtA[2][1]) * invDet;
    invAtA[0][1] = -(AtA[0][1] * AtA[2][2] - AtA[0][2] * AtA[2][1]) * invDet;
    invAtA[0][2] =  (AtA[0][1] * AtA[1][2] - AtA[0][2] * AtA[1][1]) * invDet;
    invAtA[1][0] = -(AtA[1][0] * AtA[2][2] - AtA[1][2] * AtA[2][0]) * invDet;
    invAtA[1][1] =  (AtA[0][0] * AtA[2][2] - AtA[0][2] * AtA[2][0]) * invDet;
    invAtA[1][2] = -(AtA[0][0] * AtA[1][2] - AtA[0][2] * AtA[1][0]) * invDet;
    invAtA[2][0] =  (AtA[1][0] * AtA[2][1] - AtA[1][1] * AtA[2][0]) * invDet;
    invAtA[2][1] = -(AtA[0][0] * AtA[2][1] - AtA[0][1] * AtA[2][0]) * invDet;
    invAtA[2][2] =  (AtA[0][0] * AtA[1][1] - AtA[0][1] * AtA[1][0]) * invDet;

    // Calculate the final coordinates: inv(At * A) * (At * B)
    for (int i = 0; i < 3; i++) {
        coords[i] = 0;
        for (int j = 0; j < 3; j++) {
            coords[i] += invAtA[i][j] * AtB[j];
        }
    }
}

int main() {
    double baseStations[MAX_STATIONS][3] = {
        {0.0, 0.0, 0.0},
        {10.0, 0.0, 0.0},
        {0.0, 10.0, 0.0},
        {0.0, 0.0, 10.0}
    };

    double distances[MAX_STATIONS] = {12.0, 8.0, 10.0, 6.0};
    double coords[3] = {0};

    multilateration3D(baseStations, distances, 4, coords);

    printf("Estimated coordinates: (%.2f, %.2f, %.2f)\n", coords[0], coords[1], coords[2]);

    return 0;
}
