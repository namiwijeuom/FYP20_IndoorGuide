import numpy as np
import matplotlib.pyplot as plt

class ParticleFilter:
    def __init__(self, num_particles, space_dim, anchors, noise_std=0.5):
        self.num_particles = num_particles
        self.particles = np.random.uniform(0, space_dim, (num_particles, 2))  # Random initial positions
        self.weights = np.ones(num_particles) / num_particles  # Initial equal weights
        self.anchors = anchors  # Anchor points (known positions)
        self.noise_std = noise_std

    def predict(self, movement):
        """Move particles according to the given movement (with added noise)."""
        noise = np.random.normal(0, self.noise_std, self.particles.shape)
        self.particles += movement + noise

    def update_weights(self, observed_distances):
        """Update particle weights based on the difference between predicted and observed distances."""
        for i, particle in enumerate(self.particles):
            predicted_distances = np.linalg.norm(self.anchors - particle, axis=1)
            self.weights[i] = np.exp(-np.sum((predicted_distances - observed_distances) ** 2))

        # Normalize weights
        self.weights += 1.e-300  # Prevent divide by zero
        self.weights /= np.sum(self.weights)

    def resample(self):
        """Resample particles based on their weights."""
        indices = np.random.choice(range(self.num_particles), size=self.num_particles, p=self.weights)
        self.particles = self.particles[indices]
        self.weights.fill(1.0 / self.num_particles)

    def estimate(self):
        """Return the estimated position (weighted mean of particles)."""
        return np.average(self.particles, weights=self.weights, axis=0)

    def run(self, movements, observations):
        """Run the particle filter through a series of movements and observations."""
        estimates = []

        for movement, observed_distances in zip(movements, observations):
            self.predict(movement)
            self.update_weights(observed_distances)
            self.resample()
            estimates.append(self.estimate())

        return np.array(estimates)

# Simulation parameters
num_particles = 1000
space_dim = 100  # 100x100 meter space
anchors = np.array([[0, 0], [0, 100], [100, 0], [100, 100]])  # Corners of the space

# Movements and observations (simulated for testing)
movements = [np.array([1, 1]) for _ in range(50)]  # Simulate constant movement of 1m in both x and y
true_positions = np.cumsum(movements, axis=0)
observations = [np.linalg.norm(anchors - pos, axis=1) + np.random.normal(0, 0.5, len(anchors)) for pos in true_positions]

# Run the particle filter
pf = ParticleFilter(num_particles, space_dim, anchors)
estimates = pf.run(movements, observations)

# Plot results
plt.plot(true_positions[:, 0], true_positions[:, 1], label="True Path")
plt.plot(estimates[:, 0], estimates[:, 1], label="Estimated Path", linestyle='--')
plt.scatter(anchors[:, 0], anchors[:, 1], label="Anchors", color='red')
plt.legend()
plt.xlabel('X Position')
plt.ylabel('Y Position')
plt.title('Particle Filter for Indoor Localization')
plt.show()
