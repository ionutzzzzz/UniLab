% 69_advanced_ml_ensemble_automl.m
% UniLab Complex ML Pipeline: AutoML Regression with Feature Scaling and Dimensionality Reduction
% This script constructs a full machine learning workflow: synthetic non-linear data generation,
% robust scaling, AutoML regression model search, PCA projection, and DBSCAN anomaly detection.

clear all;
close all;
clc;

disp('🤖 UniLab Complex Machine Learning Pipeline');
disp('=============================================');

% Step 1: Generate non-linear synthetic dataset (noisy sinusoidal helix)
disp('Generating synthetic dataset (3D non-linear helix with noise)...');
n_samples = 40;
X = [];
y = [];

for i = 1:n_samples
    t_val = (i / n_samples) * 4.0 * pi;
    % Features: spiral coordinates
    x1 = sin(t_val) + 0.1 * randn(1);
    x2 = cos(t_val) + 0.1 * randn(1);
    x3 = t_val * 0.5 + 0.1 * randn(1);
    X = [X; x1, x2, x3];
    
    % Target: non-linear function
    target = sin(x1) * cos(x2) + x3 * 0.2 + 0.05 * randn(1);
    y = [y; target];
end

% Step 2: Feature Scaling using RobustScaler
disp('Scaling features using RobustScaler...');
scaler = ml.RobustScaler();
X_scaled = scaler.fit_transform(X);

% Step 3: Run AutoML Auto-Trainer for Regression
disp('Running AutoML regression search to locate best model...');
best_reg = ml.fitAutoML(X_scaled, y, 'regression', true);

% Step 4: Predict and evaluate performance metrics
y_pred = best_reg.predict(X_scaled);
mse = mean((y_pred - y).^2);
mae = mean(abs(y_pred - y));

fprintf('--- Model Performance on Training Set ---\n');
fprintf('  Mean Squared Error (MSE):  %.6f\n', mse);
fprintf('  Mean Absolute Error (MAE): %.6f\n', mae);

% Step 5: Dimensionality Reduction via PCA
disp('Projecting features to 2D space using Principal Component Analysis (PCA)...');
pca_obj = ml.PrincipalComponentAnalysis(2);
X_pca = pca_obj.fit_transform(X_scaled);

% Step 6: Cluster the projected features using DBSCAN
disp('Performing density-based clustering (DBSCAN) on PCA features...');
dbscan_obj = ml.DBSCAN(0.5, 2);
clusters = dbscan_obj.fit_predict(X_pca);

% Print clustering information
disp('First 10 sample projections and DBSCAN clusters:');
for i = 1:10
    fprintf('  Sample %02d | PCA: [%.4f, %.4f] | Cluster ID: %d\n', i, X_pca(i, 1), X_pca(i, 2), clusters(i));
end

% Plot original vs predicted target values
figure;
plot(1:n_samples, y, 'c-o', 1:n_samples, y_pred, 'y-*', 'LineWidth', 1.5);
title('AutoML Regressor: Target vs Predicted Values');
xlabel('Sample Index');
ylabel('Value');
grid on;

disp('ML pipeline execution completed.');
