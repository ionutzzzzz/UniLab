% 07_ml_ensembles.m
% UniLab Advanced ML: Random Forests, Gradient Boosting, and Anomaly Detection

disp('📈 UniLab Machine Learning Ensemble Lab');
disp('=======================================');

%% 1. Random Forest Classification
disp('--- 1. Random Forest ---');
X = rand(200, 5);
% Nonlinear boundary: y is 1 if sum of squared features > 0.8
y = (sum(X.^2, 2) > 0.8);

rf = ml.RandomForest('n_trees', 50, 'max_depth', 10);
rf.fit(X, y);
train_acc = ml.accuracy_score(y, rf.predict(X));
disp(['Random Forest Training Accuracy: ', num2str(train_acc * 100), '%']);

%% 2. Gradient Boosting (GBM) Regression
disp(' ');
disp('--- 2. Gradient Boosting (GBM) ---');
X_reg = (0:0.1:10)';
y_reg = sin(X_reg) + 0.1*randn(length(X_reg), 1);

gbm = ml.GradientBoosting('n_estimators', 100, 'lr', 0.1, 'task', 'regression');
gbm.fit(X_reg, y_reg);
disp('GBM Model trained on noisy sine wave.');

%% 3. Anomaly Detection (Isolation Forest)
disp(' ');
disp('--- 3. Anomaly Discovery ---');
% Normal data centered at (0,0) plus some extreme outliers
X_anom = [randn(100, 2); 10, 10; -10, -10; 8, -5];
iso = ml.IsolationForest('n_estimators', 100);
iso.fit(X_anom);
scores = iso.predict(X_anom);
disp('Isolation Forest identified structure in 103 samples.');

%% 4. Comparative Visualization
disp(' ');
disp('Launching Interactive ML Simulator for Model Comparison...');
simulate(rf, 'X', X, 'y', y, 'epochs', 1, 'title', 'RF Decision Boundary');

disp(' ');
disp('Ensemble Lab Complete.');
