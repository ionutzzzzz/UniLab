% 12_gui_ml_simulation.m
% Test the new interactive GUI ML simulation

disp('Starting ML Training Simulator...');

% Create simple dataset (XOR problem)
X = [0 0; 0 1; 1 0; 1 1];
y = [0; 1; 1; 0];

% Create a Neural Network with 1 hidden layer
net = ml.NeuralNet([2, 4, 1], 'tanh');

% Launch the interactive simulation GUI
simulate(net, 'X', X, 'y', y, 'epochs', 500, 'lr', 0.1);

disp('Simulation closed.');