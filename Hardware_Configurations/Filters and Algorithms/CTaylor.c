#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#define MAX_BASE_STATIONS 100

void chan_algorithm(double baseLocs[][3], double *distances, int n, double *position) {
    // Ensure there are enough base stations
    if (n < 4) {
        position[0] = NAN;
        position[1] = NAN;
        position[2] = NAN;
        return;
    }

    // Matrices for the system of equations
    double A[MAX_BASE_STATIONS][3] = {0};
    double b[MAX_BASE_STATIONS] = {0};

    // Calculate A and b based on Chan's algorithm
    for (int i = 1; i < n; i++) {
        A[i - 1][0] = baseLocs[i][0] - baseLocs[0][0];
        A[i - 1][1] = baseLocs[i][1] - baseLocs[0][1];
        A[i - 1][2] = baseLocs[i][2] - baseLocs[0][2];

        b[i - 1] = 0.5 * (
            pow(distances[0], 2) - pow(distances[i], 2)
            - (pow(baseLocs[0][0], 2) + pow(baseLocs[0][1], 2) + pow(baseLocs[0][2], 2))
            + (pow(baseLocs[i][0], 2) + pow(baseLocs[i][1], 2) + pow(baseLocs[i][2], 2))
        );
    }

    // Transpose of A
    double At[3][MAX_BASE_STATIONS] = {0};
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < 3; j++) {
            At[j][i] = A[i][j];
        }
    }

    // At * A
    double AtA[3][3] = {0};
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            for (int k = 0; k < n - 1; k++) {
                AtA[i][j] += At[i][k] * A[k][j];
            }
        }
    }

    // At * b
    double Atb[3] = {0};
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < n - 1; j++) {
            Atb[i] += At[i][j] * b[j];
        }
    }

    // Invert AtA (3x3 matrix inversion)
    double det = AtA[0][0] * (AtA[1][1] * AtA[2][2] - AtA[1][2] * AtA[2][1])
               - AtA[0][1] * (AtA[1][0] * AtA[2][2] - AtA[1][2] * AtA[2][0])
               + AtA[0][2] * (AtA[1][0] * AtA[2][1] - AtA[1][1] * AtA[2][0]);

    if (fabs(det) < 1e-6) {
        position[0] = NAN;
        position[1] = NAN;
        position[2] = NAN;
        return;
    }

    double invDet = 1.0 / det;

    double invAtA[3][3] = {0};
    invAtA[0][0] =  (AtA[1][1] * AtA[2][2] - AtA[1][2] * AtA[2][1]) * invDet;
    invAtA[0][1] = -(AtA[0][1] * AtA[2][2] - AtA[0][2] * AtA[2][1]) * invDet;
    invAtA[0][2] =  (AtA[0][1] * AtA[1][2] - AtA[0][2] * AtA[1][1]) * invDet;
    invAtA[1][0] = -(AtA[1][0] * AtA[2][2] - AtA[1][2] * AtA[2][0]) * invDet;
    invAtA[1][1] =  (AtA[0][0] * AtA[2][2] - AtA[0][2] * AtA[2][0]) * invDet;
    invAtA[1][2] = -(AtA[0][0] * AtA[1][2] - AtA[0][2] * AtA[1][0]) * invDet;
    invAtA[2][0] =  (AtA[1][0] * AtA[2][1] - AtA[1][1] * AtA[2][0]) * invDet;
    invAtA[2][1] = -(AtA[0][0] * AtA[2][1] - AtA[0][1] * AtA[2][0]) * invDet;
    invAtA[2][2] =  (AtA[0][0] * AtA[1][1] - AtA[0][1] * AtA[1][0]) * invDet;

    // Calculate position: inv(At * A) * (At * b)
    for (int i = 0; i < 3; i++) {
        position[i] = 0;
        for (int j = 0; j < 3; j++) {
            position[i] += invAtA[i][j] * Atb[j];
        }
    }
}

void c_taylor_algorithm(double baseLocs[][3], double *distances, int n, double *initial_position, double *refined_position) {
    // Parameters
    const double threshold = 0.0001;
    const int max_iter = 100;

    double position[3] = {initial_position[0], initial_position[1], initial_position[2]};

    // Iterative Taylor series refinement
    for (int iter = 0; iter < max_iter; iter++) {
        double residuals[MAX_BASE_STATIONS] = {0};
        double jacobian[MAX_BASE_STATIONS][3] = {0};

        for (int j = 0; j < n; j++) {
            // Estimate distance based on current position
            double d_est = sqrt(
                pow(position[0] - baseLocs[j][0], 2) +
                pow(position[1] - baseLocs[j][1], 2) +
                pow(position[2] - baseLocs[j][2], 2)
            );
            residuals[j] = distances[j] - d_est;

            // Compute Jacobian for Taylor series expansion
            jacobian[j][0] = (position[0] - baseLocs[j][0]) / d_est;
            jacobian[j][1] = (position[1] - baseLocs[j][1]) / d_est;
            jacobian[j][2] = (position[2] - baseLocs[j][2]) / d_est;
        }

        // Solve for delta_position using weighted least squares
        double Jt[3][MAX_BASE_STATIONS] = {0}; // Transpose of Jacobian
        double JtJ[3][3] = {0};               // Jt * J
        double JtR[3] = {0};                  // Jt * residuals

        for (int i = 0; i < n; i++) {
            for (int j = 0; j < 3; j++) {
                Jt[j][i] = jacobian[i][j];
            }
        }

        for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 3; j++) {
                for (int k = 0; k < n; k++) {
                    JtJ[i][j] += Jt[i][k] * jacobian[k][j];
                }
            }
        }

        for (int i = 0; i < 3; i++) {
            for (int k = 0; k < n; k++) {
                JtR[i] += Jt[i][k] * residuals[k];
            }
        }

        // Invert JtJ (3x3 matrix inversion)
        double det = JtJ[0][0] * (JtJ[1][1] * JtJ[2][2] - JtJ[1][2] * JtJ[2][1])
                   - JtJ[0][1] * (JtJ[1][0] * JtJ[2][2] - JtJ[1][2] * JtJ[2][0])
                   + JtJ[0][2] * (JtJ[1][0] * JtJ[2][1] - JtJ[1][1] * JtJ[2][0]);

        if (fabs(det) < 1e-6) {
            refined_position[0] = NAN;
            refined_position[1] = NAN;
            refined_position[2] = NAN;
            return;
        }

        double invDet = 1.0 / det;
        double invJtJ[3][3] = {0};

        invJtJ[0][0] =  (JtJ[1][1] * JtJ[2][2] - JtJ[1][2] * JtJ[2][1]) * invDet;
        invJtJ[0][1] = -(JtJ[0][1] * JtJ[2][2] - JtJ[0][2] * JtJ[2][1]) * invDet;
        invJtJ[0][2] =  (JtJ[0][1] * JtJ[1][2] - JtJ[0][2] * JtJ[1][1]) * invDet;
        invJtJ[1][0] = -(JtJ[1][0] * JtJ[2][2] - JtJ[1][2] * JtJ[2][0]) * invDet;
        invJtJ[1][1] =  (JtJ[0][0] * JtJ[2][2] - JtJ[0][2] * JtJ[2][0]) * invDet;
        invJtJ[1][2] = -(JtJ[0][0] * JtJ[1][2] - JtJ[0][2] * JtJ[1][0]) * invDet;
        invJtJ[2][0] =  (JtJ[1][0] * JtJ[2][1] - JtJ[1][1] * JtJ[2][0]) * invDet;
        invJtJ[2][1] = -(JtJ[0][0] * JtJ[2][1] - JtJ[0][1] * JtJ[2][0]) * invDet;
        invJtJ[2][2] =  (JtJ[0][0] * JtJ[1][1] - JtJ[0][1] * JtJ[1][0]) * invDet;

        double delta_position[3] = {0};
        for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 3; j++) {
                delta_position[i] += invJtJ[i][j] * JtR[j];
            }
        }

        // Update position
        position[0] += delta_position[0];
        position[1] += delta_position[1];
        position[2] += delta_position[2];

        // Check convergence
        if (sqrt(pow(delta_position[0], 2) + pow(delta_position[1], 2) + pow(delta_position[2], 2)) < threshold) {
            break;
        }
    }

    refined_position[0] = position[0];
    refined_position[1] = position[1];
    refined_position[2] = position[2];
}

int main() {
    double baseLocs[MAX_BASE_STATIONS][3] = {
        {0.0, 0.0, 0.0},
        {10.0, 0.0, 0.0},
        {0.0, 10.0, 0.0},
        {0.0, 0.0, 10.0}
    };

    double distances[MAX_BASE_STATIONS] = {12.0, 8.0, 10.0, 6.0};
    double initial_position[3] = {5.0, 5.0, 5.0};
    double refined_position[3] = {0};

    chan_algorithm(baseLocs, distances, 4, initial_position);
    c_taylor_algorithm(baseLocs, distances, 4, initial_position, refined_position);

    printf("Estimated position (Chan): (%.2f, %.2f, %.2f)\n", initial_position[0], initial_position[1], initial_position[2]);
    printf("Refined position (C-Taylor): (%.2f, %.2f, %.2f)\n", refined_position[0], refined_position[1], refined_position[2]);

    return 0;
}
