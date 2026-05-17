disp('🔬 UniLab: Machine Learning Research Suite');
disp('=========================================');

% 1. Preprocessing with Polynomial Expansion
disp('--- 1. Feature Engineering ---');
X = [1; 2; 3; 4; 5];
y = [1.2; 4.1; 8.8; 16.2; 24.5];
poly = ml.PolynomialFeatures(2, true);
X_poly = poly.fit_transform(X);
disp('Polynomial Features (Bias, x, x^2):');
disp(X_poly);

% 2. Scaling & Random Forest
disp(' ');
disp('--- 2. Scaled Random Forest ---');
raw_data = rand(50, 4);
targets = (raw_data(:, 1) + raw_data(:, 2) > 1.0); % non-linear classification

scaler = ml.StandardScaler();
X_scaled = scaler.fit_transform(raw_data);

% n_trees, max_depth, min_samples_split, max_features, bootstrap, task
rf = ml.RandomForest(20, 10, 2, 'sqrt', true, 'classification');
rf.fit(X_scaled, targets);
preds = rf.predict(X_scaled);
acc = ml.accuracy_score(targets, preds);
disp(['RF Training Accuracy: ', num2str(acc * 100), '%']);

% 3. Unsupervised: Hierarchical Agglomerative Clustering
disp(' ');
disp('--- 3. Hierarchical Clustering ---');
X_cluster = [1 1; 1.2 1.1; 5 5; 5.2 5.1; 10 10; 10.1 9.8];
agg = ml.AgglomerativeClustering(3);
labels = agg.fit_predict(X_cluster);
disp('Assigned cluster labels (k=3):');
disp(labels');

% 4. Gaussian Process Regression
disp(' ');
disp('--- 4. Probabilistic Regression (GPR) ---');
gp = ml.GaussianProcessRegressor(1e-4);
gp.fit(X, y);
X_new = [1.5; 2.5; 3.5; 4.5];
mu = gp.predict(X_new);
disp('Interpolated GPR values:');
disp(mu');

disp(' ');
disp('ML Research Complete.');
