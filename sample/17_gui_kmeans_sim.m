% 17_gui_kmeans_sim.m
% Test the interactive K-Means Clustering Simulator

disp('Starting K-Means Simulator...');

% Generate 3 distinct blobs of data
X1 = randn(50, 2) + [2 2];
X2 = randn(50, 2) + [8 8];
X3 = randn(50, 2) + [2 8];
X = [X1; X2; X3];

% Create a KMeans model with k=3
model = ml.KMeans('k', 3, 'max_iters', 50);

% Launch the interactive simulation GUI
simulate(model, 'X', X);

disp('Simulation closed.');