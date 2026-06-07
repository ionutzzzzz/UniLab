% 53_ml_random_forest_maintenance.m
% UniLab Machine Learning: Ensemble Learning with Random Forests

clear all;
clc;

disp('🤖 UniLab Machine Learning: Random Forest Classifier');
disp('=====================================================');

%% 1. Data Generation (Predictive Maintenance Scenario)
disp('--- 1. Generating Machine Fault Data ---');
% Features: [Vibration, Temperature, Noise]
% Classes: 1: Normal, 2: Bearing Failure, 3: Overheating
num_samples = 200;
num_features = 3;
num_classes = 3;

[X, y] = make_blobs(num_samples, num_features, num_classes, 1.1);

% Split into training and testing sets (80/20)
[X_train, X_test, y_train, y_test] = train_test_split(X, y, 0.2);

fprintf('Training set size: %d samples\n', size(X_train, 1));
fprintf('Testing set size:  %d samples\n', size(X_test, 1));

%% 2. Training Random Forest
disp('--- 2. Training Random Forest Ensemble ---');
n_trees = 10;
max_depth = 6;
min_samples_split = 2;
max_features = 2; 

% Note: random_forest_train uses decision_tree_train internally
forest = random_forest_train(X_train, y_train, n_trees, max_depth, min_samples_split, max_features);

fprintf('Trained ensemble of %d decision trees.\n', n_trees);

%% 3. Prediction and Evaluation
disp(' ');
disp('--- 3. Evaluation on Unseen Test Data ---');
y_pred = random_forest_predict(X_test, forest);

acc = accuracy(y_test, y_pred);
fprintf('Random Forest Accuracy: %.2f%%\n', acc * 100);

% Detailed class performance
cm = confusion_matrix(y_test, y_pred, num_classes);
disp('Confusion Matrix (Rows: Actual, Cols: Predicted):');
plot_matrix(cm);

%% 4. Advanced Evaluation
disp('--- 4. Ensemble Diversity Analysis ---');
% Evaluate individual tree performance on the same test set
for i = 1:min(5, n_trees)
    tree_pred = decision_tree_predict(X_test, forest{i});
    tree_acc = accuracy(y_test, tree_pred);
    fprintf('  Tree %d Accuracy: %.2f%%\n', i, tree_acc * 100);
end

disp('The Random Forest accuracy should be higher than most individual trees.');
disp('Machine Intelligence Simulation Complete.');
