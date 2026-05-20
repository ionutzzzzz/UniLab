% 02_machine_learning.m
% UniLab Machine Learning: From Preprocessing to Live Neural Training

disp('🧠 UniLab Machine Learning Laboratory');
disp('=====================================');

%% 1. Preprocessing & Feature Engineering
disp('--- 1. Feature Engineering ---');
X_raw = [1, 2; 2, 4; 3, 6; 4, 8];
poly = ml.PolynomialFeatures(2);
X_poly = poly.fit_transform(X_raw);
disp(['Polynomial Expansion (degree 2): ', num2str(size(X_poly, 2)), ' features']);

%% 2. Unsupervised Clustering
disp(' ');
disp('--- 2. K-Means Clustering ---');
X_cluster = [(randn(50, 2) + 2); (randn(50, 2) - 2); (randn(50, 2) + [2, -2])];
km = ml.KMeans('k', 3);
km.fit(X_cluster);
disp(['Final Centroids:']);
disp(km.centroids);

%% 3. Live Neural Network Training
disp(' ');
disp('--- 3. Interactive Neural Net Visualization ---');
% Generate complex non-linear XOR-like dataset
n = 100;
X = [(randn(n, 2) + 2); (randn(n, 2) - 2); (randn(n, 2) + [2, -2]); (randn(n, 2) + [-2, 2])];
y = [zeros(2*n, 1); ones(2*n, 1)];

% Create model with Tanh activation and Dropout
net = ml.NeuralNet('layers', [2, 12, 1], 'activation', 'tanh', 'dropout', 0.1);

% Custom initialization to build a dashboard
function nn_init()
    uilabel('title', '--- NN Control Panel ---');
    uicheckbox('Auto-Restart', false, @(v) disp(['Auto-restart: ', num2str(v)]));
    uidropdown('Optimizer', {'adam', 'sgd'}, @(o) uiset('status', ['Using: ', o]));
    uilabel('status', 'Network ready for training.');
end

disp('Launching Live Training Simulator...');
simulate(net, 'X', X, 'y', y, 'epochs', 2000, 'lr', 0.01, 'on_init', @nn_init);

disp(' ');
disp('Machine Learning Laboratory Complete.');
