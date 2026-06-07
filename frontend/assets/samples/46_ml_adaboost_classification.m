% 46_ml_adaboost_classification.m
% UniLab Machine Learning: Ensemble Methods (AdaBoost)

clear all;
close all;
clc;

disp('🤖 UniLab Machine Learning: AdaBoost');
disp('======================================');

disp('--- 1. Generating Data ---');
% Generate synthetic classification data (Moons)
[X, y] = make_moons(200, 0.15);

% AdaBoost requires labels to be {-1, 1}
y_ada = y;
y_ada(y_ada == 0) = -1;

% Split data into 70% train and 30% test
[X_train, X_test, y_train, y_test] = train_test_split(X, y_ada, 0.3);

disp('--- 2. Training AdaBoost Ensemble ---');
n_estimators = 30;
model = adaboost_train(X_train, y_train, n_estimators);
fprintf('Trained AdaBoost model with %d decision stumps.\n', n_estimators);

disp('--- 3. Evaluation on Test Set ---');
y_pred = adaboost_predict(X_test, model);

% Convert back to {0, 1} for standard evaluation metrics
y_test_bin = y_test;
y_test_bin(y_test_bin == -1) = 0;
y_pred_bin = y_pred;
y_pred_bin(y_pred_bin == -1) = 0;

acc = accuracy(y_test_bin, y_pred_bin);
prec = precision_score(y_test_bin, y_pred_bin);
rec = recall_score(y_test_bin, y_pred_bin);
f1 = f1_score(y_test_bin, y_pred_bin);

fprintf('Accuracy:  %.2f%%\n', acc * 100);
fprintf('Precision: %.4f\n', prec);
fprintf('Recall:    %.4f\n', rec);
fprintf('F1 Score:  %.4f\n', f1);

disp('--- 4. Visualizing Results ---');
figure;
scatter_plot(X_test(:, 1), X_test(:, 2), 'AdaBoost Test Set Distributions');

disp('AdaBoost Classification Simulation Complete.');