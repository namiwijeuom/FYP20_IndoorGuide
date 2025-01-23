% Initialize Python if not already done
if count(py.sys.path, '') == 0
    insert(py.sys.path, int32(0), '');
end

% Import Python libraries for TensorFlow
py.importlib.import_module('tensorflow');

% Load the model from the specified path
model = py.tensorflow.keras.models.load_model('C:\Users\Namina Wijetunga\Desktop\FYP\FYP20_IndoorGuide\Classification_Model\model.h5');

% Prepare your input data in MATLAB
% Assuming X1 and X2 are your two input matrices
inputData1 = X1;  % First input
inputData2 = X2;  % Second input

% Convert MATLAB arrays to Python arrays
inputData1Py = py.numpy.array(inputData1);
inputData2Py = py.numpy.array(inputData2);

% Pass both inputs as a tuple to the model's predict method
inputToModel = py.tuple({inputData1Py, inputData2Py}) ;
predictions = model.predict(inputToModel);

% Convert predictions back to MATLAB array (if needed)
predictedLabel = double(predictions);
disp('Predicted Label:');
disp(predictedLabel);


% Load the Keras model
%net = importKerasNetwork('model.h5', 'OutputLayerType', 'classification');

% Prepare sample input data (adjust dimensions based on your model's requirements)
%inputData = rand(100, 1);  % Replace with actual sample values
%inputData = reshape(inputData, [100, 1, 1]);  % Reshape to match the input dimensions

% Perform prediction
%predictedLabel = classify(net, inputData);
%disp('Predicted Label:');
%disp(predictedLabel);

% Get class scores (if needed)
%classScores = predict(model, inputToModel);
%disp('Class Scores:');
%disp(classScores);

%Find and display the predicted class with the highest score
%[~, predictedClass] = max(classScores);
%disp(['Predicted Class: ', num2str(predictedClass)]);
