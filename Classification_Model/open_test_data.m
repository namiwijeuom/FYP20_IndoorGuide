% Specify the path to your CSV file
filename = 'Rand_5_pdp_3_External_cir_and_pdp_set_3_TEST__normalized_1.csv';

% Read the CSV file into a table
data = readtable(filename);

% Display the first few rows of the data
%disp('First few rows of the data:');
%disp(head(data));

% If you want to convert the table to an array for numerical computations
data_array = table2array(data);
disp(data_array)

% Display the dimensions and type of data read
%disp('Data dimensions:');
%disp(size(data));

% Example: Accessing specific columns or rows and assigning columns to variables
NLOS = data_array(:, 1) ;
Measured_range = data_array(:, 2);
FP_IDX = data_array(:, 3);
FP_AMP1 = data_array(:, 4);
FP_AMP2 = data_array(:, 5);
FP_AMP3 = data_array(:, 6);
STDEV_NOISE = data_array(:, 7);
CIR_PWR = data_array(:, 8);
MAX_NOISE = data_array(:, 9);
RXPACC = data_array(:, 10);
CH = data_array(:, 11);
FRAME_LEN = data_array(:, 12);
PREAM_LEN = data_array(:, 13);
BITRATE = data_array(:, 14);
PRFR = data_array(:, 15);
CIR = data_array(:, 16:end); % Assuming the CIR is in the remaining columns

% Concatenate variables horizontally to create X1
X1 = [FP_IDX, FP_AMP1, FP_AMP2, FP_AMP3, STDEV_NOISE, CIR_PWR, MAX_NOISE, RXPACC, CH, FRAME_LEN, PREAM_LEN, BITRATE, PRFR];

% Concatenate Measured_range and CIR to create X2
X2 = [Measured_range, CIR];

% Display 
%disp(X2);