%% No changes
version = 'v5';
fileName = 'W:/University of Moratuwa/Academics/Semester 7 and 8/FYP/GitHub/FYP20_IndoorGuide/Classification_Model/Preprocessing_Using_MATLAB/Measurements/External/RangingWithCIRData3_';

pdp_downsampled_out = 3;
pdp_downsampling_factor = 40;
extractFeaturesFromCir(version, fileName, pdp_downsampled_out, pdp_downsampling_factor);

pdp_downsampled_out = 7;
pdp_downsampling_factor = 20;
extractFeaturesFromCir(version, fileName, pdp_downsampled_out, pdp_downsampling_factor);

pdp_downsampled_out = 15;
pdp_downsampling_factor = 10;
extractFeaturesFromCir(version, fileName, pdp_downsampled_out, pdp_downsampling_factor);

pdp_downsampled_out = 30;
pdp_downsampling_factor = 5;
extractFeaturesFromCir(version, fileName, pdp_downsampled_out, pdp_downsampling_factor);