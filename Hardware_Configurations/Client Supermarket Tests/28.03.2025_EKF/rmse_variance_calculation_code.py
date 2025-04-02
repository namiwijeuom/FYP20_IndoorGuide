import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os
from scipy.stats import mode

# Fixed coordinates for each file (replace with your actual fixed coordinates)
fixed_coordinates = {
    'A': (4.95, 6.25),
    'B': (7.45, 6.25),  
    'C': (9.95, 6.25), 
    'D': (9.95, 11.00),  
    'E': (7.45, 11.00),  
    'F': (4.95, 11.00),  
    'G': (4.95, 15.00),  
    'H': (7.45, 15.00),  
    'I': (9.95, 15.00),  
    'P': (7.70, 5.00),  
    'Q': (9.95, 16.50),  
    'R': (6.20, 16.50),  
}

# Initialize a list to store results
results = []

# Create a directory to save plots
os.makedirs('C:/Users/Namina Wijetunga/Desktop/IndoorGuide/FYP20_IndoorGuide/Hardware_Configurations/Client Supermarket Tests/28.03.2025_EKF/error_plots', exist_ok=True)

# Process each file
for file_id, (fixed_x, fixed_y) in fixed_coordinates.items():
    file_name = f'C:/Users/Namina Wijetunga/Desktop/IndoorGuide/FYP20_IndoorGuide/Hardware_Configurations/Client Supermarket Tests/28.03.2025_EKF/Collected_Datasets/data_log_EKF_{file_id}.csv'
    
    # Check if the file exists
    if not os.path.exists(file_name):
        print(f"File {file_name} not found. Skipping.")
        continue
    
    # Load the data
    try:
        data = pd.read_csv(file_name)
        print(f"Processing {file_name}...")
    except Exception as e:
        print(f"Error loading {file_name}: {e}")
        continue
    
    # Check if the file has the required columns
    if 'X' not in data.columns or 'Y' not in data.columns:
        print(f"File {file_name} does not have 'X' and 'Y' columns. Skipping.")
        continue
    
    # Calculate errors
    data['error_x'] = data['X'] - fixed_x
    data['error_y'] = data['Y'] - fixed_y
    data['error_xy'] = np.sqrt(data['error_x']**2 + data['error_y']**2)

    # Calculate RMSE
    rmse = np.sqrt(np.mean(data['error_xy']**2))

    # Calculate maximum errors
    max_error_x = np.max(np.abs(data['error_x']))
    max_error_y = np.max(np.abs(data['error_y']))

    # Calculate variances
    var_x = np.var(data['X'])
    var_y = np.var(data['Y'])
    var_xy = np.var(data['error_xy'])

    # Calculate most frequent errors (mode)
    mode_error_x = mode(data['error_x']).mode[0]  # Most frequent error for x
    mode_error_y = mode(data['error_y']).mode[0]  # Most frequent error for y

    # Append results to the list
    results.append({
        'File': file_id,
        'Max_Error_X': max_error_x,
        'Max_Error_Y': max_error_y,
        'Mode_Error_X': mode_error_x,
        'Mode_Error_Y': mode_error_y,
        'RMSE': rmse,
        'Variance_X': var_x,
        'Variance_Y': var_y,
        'Variance_XY': var_xy,
    })

    # Plot error distribution
    plt.figure(figsize=(10, 6))
    plt.hist(data['error_xy'], bins=50, color='orange', alpha=0.7)
    plt.title(f'Error Distribution of Point {file_id} in Meters')
    plt.xlabel('Error')
    plt.ylabel('Frequency')
    plt.grid(True)
    plot_path = f'C:/Users/Namina Wijetunga/Desktop/IndoorGuide/FYP20_IndoorGuide/Hardware_Configurations/Client Supermarket Tests/28.03.2025_EKF/error_plots/{file_id}_error_distribution.png'
    plt.savefig(plot_path)  # Save the plot
    plt.close()
    print(f"Plot saved to {plot_path}")

path_to_save = 'C:/Users/Namina Wijetunga/Desktop/IndoorGuide/FYP20_IndoorGuide/Hardware_Configurations/Client Supermarket Tests/28.03.2025_EKF/results_28_03_2025.csv'

# Save results to a CSV file
if results:
    results_df = pd.DataFrame(results)
    results_df.to_csv(path_to_save, index=False)
    print("Results saved to 'results_28_03_2025.csv'.")
else:
    print("No results to save. Check if any files were processed.")

