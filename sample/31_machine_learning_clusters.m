% 31_machine_learning_clusters.m
% UniLab Machine Learning: Predictive Maintenance & Cluster Analysis

clear all;
clc;

disp('🏭 UniLab Industrial Machine Intelligence');
disp('========================================');

%% 1. Synthetic Sensor Data Generation
disp('--- 1. Sensor Data Generation (Vibration vs. Temperature) ---');
N_pts = 300;
% Normal operating state (Cluster 1)
X_normal = randn(100, 2) * 0.5 + [2, 2];
% High stress/Caution state (Cluster 2)
X_stress = randn(100, 2) * 0.7 + [5, 4];
% Failing/Critical state (Cluster 3)
X_fail = randn(100, 2) * 0.6 + [4, 8];

X = [X_normal; X_stress; X_fail];
y_true = [ones(100, 1); 2*ones(100, 1); 3*ones(100, 1)];

figure;
scatter_plot(X(:, 1), X(:, 2), 'Raw Industrial Sensor Streams');
xlabel('Vibration (mm/s)'); ylabel('Temperature (deg C)');

%% 2. Dimensionality Reduction (PCA)
disp('--- 2. Feature Extraction with PCA ---');
% Center the data
X_mean = mean(X);
X_centered = X - X_mean;

% Calculate covariance and eigenvalues
C = (X_centered' * X_centered) / (N_pts - 1);
% In UniLab, we can use eig for small matrices
[V, D] = eig(C);
% Sort eigenvectors by variance (UniLab eig returns in ascending order)
pc1 = V(:, 2);
pc2 = V(:, 1);

% Project data onto Principal Components
X_pca = X_centered * [pc1 pc2];

figure;
plot(X_pca(1:100, 1), X_pca(1:100, 2), 'bo'); hold on;
plot(X_pca(101:200, 1), X_pca(101:200, 2), 'go');
plot(X_pca(201:300, 1), X_pca(201:300, 2), 'ro');
title('Sensor Data Projection (PCA Space)');
legend('Normal', 'Stress', 'Critical');
grid on; hold off;

%% 3. Cluster Analysis (K-Means)
disp('--- 3. Unsupervised Fault Detection (K-Means) ---');
% Try to discover states automatically
k = 3;
[idx, centroids] = kmeans(X, k);

figure;
plot_matrix(confusion_matrix(y_true, idx, 3));
title('K-Means Confusion Matrix (State Prediction)');

%% 4. Interactive Clustering Visualization
disp(' ');
disp('--- 4. Interactive K-Means Animation ---');
simulate('kmeans', 'X', X, 'k', 3);

disp('Machine Intelligence Session Complete.');
