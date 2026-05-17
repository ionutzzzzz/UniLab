disp('📈 UniLab: Advanced Ensemble Methods');
disp('====================================');

% 1. Gradient Boosting (GBM)
disp('--- 1. Gradient Boosting Ensemble ---');
X = rand(100, 5);
y = sin(X(:,1)*pi) + X(:,2).^2 + 0.1*randn(100, 1);

% n_estimators, lr, max_depth, task
gbm = ml.GradientBoosting(100, 0.1, 4, 'regression');
gbm.fit(X, y);
preds = gbm.predict(X(1:5, :));
disp('GBM Ensemble predictions for first 5 samples:');
disp(preds');

% 2. Anomaly Detection: Isolation Forest
disp(' ');
disp('--- 2. Anomaly Discovery ---');
X_anomaly = [randn(50, 2); 10 10; -10 -10]; % 2 extreme outliers
iso = ml.IsolationForest(100, 256);
iso.fit(X_anomaly);
% Isolation Forest usually returns a score where lower is more anomalous
% Here we demonstrate the structural integration
disp('Isolation Forest model trained on 52 samples.');

% 3. Support Vector Machines (Linear)
disp(' ');
disp('--- 3. Margin-Based Classification ---');
X_svm = [(randn(25, 2) + 2); (randn(25, 2) - 2)];
y_svm = [ones(25, 1); zeros(25, 1)];
svm = ml.SVM(0.01, 0.01, 1000);
svm.fit(X_svm, y_svm);
preds_svm = svm.predict(X_svm);
acc = ml.accuracy_score(y_svm, preds_svm);
disp(['SVM Separation Accuracy: ', num2str(acc * 100), '%']);

% 4. Naive Bayes (Gaussian)
disp(' ');
disp('--- 4. Probabilistic Classification ---');
nb = ml.GaussianNB();
nb.fit(X_svm, y_svm);
nb_preds = nb.predict(X_svm(1:5, :));
disp('Naive Bayes sample class predictions:');
disp(nb_preds');

disp(' ');
disp('Ensemble & Advanced ML Lab Complete.');
