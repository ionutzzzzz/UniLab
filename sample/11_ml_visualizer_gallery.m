% 11_ml_visualizer_gallery.m
% UniLab Advanced Machine Learning Visualizers
% This script demonstrates the new interactive ML and Data Science simulators.

disp('🚀 UniLab Advanced ML Visualizer Gallery');
disp('========================================');

%% 1. Regression & Curve Fitting
disp('--- 1. Polynomial Regression ---');
disp('Opening interactive regression simulator...');
% We can pass custom data or let the simulator generate it
simulate('regression', 'degree', 3);

%% 2. Support Vector Machines (SVM)
disp(' ');
disp('--- 2. SVM Maximum Margin ---');
disp('Opening SVM margin visualizer...');
simulate('svm', 'C', 1.0);

%% 3. Principal Component Analysis (PCA)
disp(' ');
disp('--- 3. PCA Projection (3D to 2D) ---');
% Generate 3D data with a clear plane
t = linspace(0, 10, 100)';
X_pca = [t, t*0.5 + randn(100, 1), t*0.2 + randn(100, 1)];
simulate('pca', 'X', X_pca);

%% 4. K-Nearest Neighbors (KNN)
disp(' ');
disp('--- 4. KNN Neighborhoods ---');
simulate('knn');

%% 5. Density-Based Clustering (DBSCAN)
disp(' ');
disp('--- 5. DBSCAN Density Search ---');
simulate('dbscan');

%% 6. Decision Tree Splits
disp(' ');
disp('--- 6. Decision Tree Boundaries ---');
simulate('tree');

%% 7. Optimizer Race (SGD vs Adam)
disp(' ');
disp('--- 7. Optimizer Trajectories ---');
simulate('optimizer');

disp(' ');
disp('✅ Advanced ML Visualizer Gallery Complete.');
