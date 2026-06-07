% 36_machine_learning_advanced_metrics.m
% UniLab Machine Learning: Manifolds, Clustering & LDA

clear all;
close all;
clc;

disp('🤖 UniLab Advanced ML Laboratory');
disp('=================================');

%% 1. Data Generation: Interleaving Moons
disp('--- 1. Generating Non-Linear Manifold (Moons) ---');
[X, y] = make_moons(200, 0.1);

figure;
scatter_plot(X(:, 1), X(:, 2), 'Interleaving Moons Data');

%% 2. Unsupervised Learning: Silhouette Evaluation
disp('--- 2. Evaluating K-Means with Silhouette Score ---');
[centroids, clusters] = kmeans(X, 2);
score = silhouette_score_approx(X, clusters);

fprintf('Silhouette Score for K=2 Clustering: %.4f\n', score);
if score > 0.5
    disp('Clustering assessment: Good separation detected.');
else
    disp('Clustering assessment: Overlapping or poor separation.');
end

%% 3. Dimensionality Reduction: LDA
disp('--- 3. Linear Discriminant Analysis (LDA) ---');
% Using 3D blobs to project onto 1D
[X3, y3] = make_blobs(150, 3, 3);
W = lda(X3, y3, 1);
X_lda = lda_predict(X3, W);

figure;
plot(X_lda(y3==1), zeros(sum(y3==1), 1), 'ro'); hold on;
plot(X_lda(y3==2), zeros(sum(y3==2), 1), 'go');
plot(X_lda(y3==3), zeros(sum(y3==3), 1), 'bo');
title('LDA Projection: 3D Blobs to 1D Line');
grid on; hold off;

%% 4. Feature Engineering: Robust Scaling
disp(' ');
disp('--- 4. Feature Scaling (Robust vs Min-Max) ---');
data_noisy = [randn(10, 1); 100]; % Outlier at the end

% Learn scaling parameters
med = median(data_noisy);
iqr_val = quantile(data_noisy, 0.75) - quantile(data_noisy, 0.25);

scaled_robust = robust_scaler_predict(data_noisy, med, iqr_val);
scaled_minmax = min_max_scaler_predict(data_noisy, min(data_noisy), max(data_noisy));

disp('Noisy data with outlier (100):');
disp(data_noisy(end-2:end));
disp('Robust Scaled (Resistant to outlier):');
disp(scaled_robust(end-2:end));
disp('Min-Max Scaled (Highly sensitive):');
disp(scaled_minmax(end-2:end));

disp('Machine Learning Advanced Metrics Session Complete.');