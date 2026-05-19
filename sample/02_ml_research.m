disp('🔬 UniLab: Advanced Machine Learning Stress Suite');
disp('==================================================');

%% 1. Preprocessing: High-Dimensional Multi-Variable Polynomial Expansion
disp('--- 1. Multi-Feature Higher-Order Engineering ---');
% Upgraded to a 3D feature space with non-linear exponential targets
X = [1, 0.5, -0.2; 2, 1.2,  0.1; 3, 2.0,  0.5; 4, 2.8,  1.2; 5, 3.5,  2.0];
y = [1.2; 5.4; 14.8; 32.2; 64.5]; 

% Degree 3 expansion creates interaction terms (e.g., x1*x2, x1^2*x3, x1*x2*x3)
poly = ml.PolynomialFeatures(3, true);
X_poly = poly.fit_transform(X);
disp(['Expanded Feature Dimensions: ', num2str(size(X_poly, 1)), 'x', num2str(size(X_poly, 2))]);
disp('Sample of Polynomial Matrix (First 2 rows):');
disp(X_poly(1:2, :));


%% 2. Scaled Random Forest: Imbalanced, Non-Linear Boundary & Validation Split
disp(' ');
disp('--- 2. High-Capacity Scaled Random Forest ---');
% Increased dataset size to 250 samples with 8 features
rng(42); % Set seed for reproducibility if supported
raw_data = rand(250, 8);

% Create a complex, highly non-linear decision boundary with a built-in class imbalance (~15% positive)
targets = (sin(raw_data(:, 1)) .* raw_data(:, 2) + log(raw_data(:, 3) + 1) - raw_data(:, 4).^2 > 0.6);

% Partition into Train (80%) and Validation (20%) sets manually to test generalization
train_idx = 1:200;
val_idx = 201:250;

scaler = ml.StandardScaler();
X_train_scaled = scaler.fit_transform(raw_data(train_idx, :));
X_val_scaled = scaler.transform(raw_data(val_idx, :)); % Note: Use .transform here if your library supports it!

% Stress test the RF: 150 trees, deeper depth, evaluating all features ('all' or numerical max)
rf = ml.RandomForest(150, 25, 2, 'all', true, 'classification');
rf.fit(X_train_scaled, targets(train_idx));

% Evaluate both sets to check for overfitting
train_preds = rf.predict(X_train_scaled);
val_preds = rf.predict(X_val_scaled);

train_acc = ml.accuracy_score(targets(train_idx), train_preds);
val_acc = ml.accuracy_score(targets(val_idx), val_preds);

disp(['RF Base Positive Class Ratio: ', num2str(mean(targets) * 100), '%']);
disp(['RF Train Accuracy: ', num2str(train_acc * 100), '%']);
disp(['RF Validation Accuracy: ', num2str(val_acc * 100), '%']);


%% 3. Unsupervised: Interleaved Multi-Cluster Structures
disp(' ');
disp('--- 3. Complex Agglomerative Clustering ---');
% 4 distinct, tightly packed or distant clusters in a 3D space to test linkage calculations
X_cluster = [
    1.0, 1.0, 1.1; 1.2, 1.1, 0.9; 1.1, 1.0, 1.0;  % Cluster 1 (Near origin)
    5.0, 5.0, 5.2; 5.2, 5.1, 4.8; 4.9, 5.0, 5.1;  % Cluster 2 (Mid-range)
    12.0, 1.0, 5.0; 12.2, 1.2, 5.1; 11.9, 0.9, 4.8; % Cluster 3 (Displaced X)
    10.0, 10.0, 10.0; 10.1, 9.8, 10.2; 9.9, 10.2, 9.7 % Cluster 4 (High range)
];

agg = ml.AgglomerativeClustering(4);
labels = agg.fit_predict(X_cluster);
disp('Assigned cluster labels for 4 distinct groups (k=4):');
disp(labels');


%% 4. Gaussian Process Regression: Matrix Inversion Stress Test
disp(' ');
disp('--- 4. Heavy Probabilistic Regression (GPR) ---');
% GPR complexity scales cubically O(N^3) with sample size due to matrix inversion.
% We upscale the training set from 5 points to 60 points to test its covariance solver.
X_gp_train = (0:0.1:5.9)'; 
y_gp_train = sin(X_gp_train) .* exp(-X_gp_train / 3) + 0.05 * randn(size(X_gp_train)); % Noisy damped sine wave

gp = ml.GaussianProcessRegressor(1e-3); % Slightly higher noise floor for stability
gp.fit(X_gp_train, y_gp_train);

% Denser prediction grid to evaluate the smoothness of the fit
X_gp_new = (0.05:0.2:5.8)';
mu = gp.predict(X_gp_new);

disp(['GPR successfully inverted a ', num2str(length(X_gp_train)), 'x', num2str(length(X_gp_train)), ' covariance matrix.']);
disp('First 5 Interpolated GPR values:');
disp(mu(1:5)');

disp(' ');
disp('Advanced ML Research Suite Complete.');