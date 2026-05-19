% 16_gui_advanced_ml_sim.m
% Test the new advanced interactive GUI for Machine Learning

disp('Starting Advanced ML Training Simulator...');

% Create a non-linear dataset (Concentric circles)
n_samples = 200;
r1 = rand(n_samples, 1) * 2;
theta1 = rand(n_samples, 1) * 2 * pi;
X1 = [r1.*cos(theta1), r1.*sin(theta1)];
y1 = zeros(n_samples, 1);

r2 = rand(n_samples, 1) * 2 + 3;
theta2 = rand(n_samples, 1) * 2 * pi;
X2 = [r2.*cos(theta2), r2.*sin(theta2)];
y2 = ones(n_samples, 1);

X = [X1; X2];
y = [y1; y2];

% Create a deeper Neural Network for non-linear boundary
net = ml.NeuralNet([2, 10, 10, 1], 'tanh');

% Launch the interactive simulation GUI
% We can tweak LR on the fly, and see the Decision Boundary tab in action!
simulate(net, 'X', X, 'y', y, 'epochs', 3000, 'lr', 0.05);

disp('Simulation closed.');