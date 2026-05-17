disp('🧠 UniLab: Neural Network Design & Simulation');
disp('=============================================');

% 1. Data Setup (The XOR Problem)
X = [0 0; 0 1; 1 0; 1 1];
y = [0; 1; 1; 0];

% 2. Network Architecture & Training
% 2 inputs, 8 hidden neurons (ReLU), 1 output
% Uses Adam optimizer and Dropout regularization
disp('--- 1. Training Architecture: [2 8 1] ---');
net = ml.NeuralNet([2, 8, 1], 'relu', 'adam', 0.1);

% train(X, y, epochs, learning_rate, l1, l2)
net.train(X, y, 3000, 0.01, 0.0, 0.001);

% 3. Verification
disp(' ');
disp('--- 2. Convergence Check ---');
results = net.predict(X);
for i = 1:4
    disp(['Input: ', mat2str(X(i,:)), ' -> Predict: ', num2str(results(i))]);
end

% 4. Professional Visualization
disp(' ');
disp('--- 3. Architecture Visualization ---');
plot_nn([2 8 1]);
title('Deep Learning: XOR MLP Architecture');

disp('Simulation Complete.');
