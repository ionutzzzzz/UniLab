disp('🧠 UniLab Pro: Advanced Neural Network Design & Evaluation');
disp('===========================================================');

%% 1. Advanced Data Setup (The Concentric Rings Problem)
% Generating non-linear, overlapping data to simulate a real-world task
disp('--- 1. Generating Synthetic Complex Dataset ---');
N = 200; % Number of points per class
r1 = rand(N,1)*0.4;          theta1 = linspace(0,2*pi,N)';
r2 = rand(N,1)*0.4 + 0.5;    theta2 = linspace(0,2*pi,N)';

% Class 0 (Inner Ring) and Class 1 (Outer Ring)
X1 = [r1.*cos(theta1), r1.*sin(theta1)];
X2 = [r2.*cos(theta2), r2.*sin(theta2)];

X_all = [X1; X2];
y_all = [zeros(N,1); ones(N,1)];

% Shuffle and perform an 80/20 Train/Test Split
rng(42); % Set seed for reproducibility
cv = cvpartition(size(X_all,1), 'HoldOut', 0.2);
idxTrain = training(cv);
idxTest = test(cv);

X_train = X_all(idxTrain, :);
y_train = y_all(idxTrain, :);
X_test  = X_all(idxTest, :);
y_test  = y_all(idxTest, :);

disp(['Training samples: ', num2str(sum(idxTrain)), ' | Test samples: ', num2str(sum(idxTest))]);

%% 2. Experiment Setup: Comparing Architectures
% We will test a standard network against a deeper, heavily regularized one
architectures = {
    [2, 8, 1],       'relu',    'Standard MLP';
    [2, 16, 8, 1],   'leaky',   'Deep Regularized MLP'
};

num_experiments = size(architectures, 1);
models = cell(num_experiments, 1);

for idx = 1:num_experiments
    layers = architectures{idx, 1};
    activation = architectures{idx, 2};
    desc = architectures{idx, 3};
    
    disp(' ');
    disp(['--- Experiment ', num2str(idx), ': ', desc, ' ---']);
    disp(['Architecture: ', mat2str(layers), ' | Activation: ', activation]);
    
    % Initialize network with Adam optimizer
    net = ml.NeuralNet(layers, activation, 'adam', 0.1);
    
    % Train with L2 regularization (weight decay) to prevent overfitting
    % net.train(X, y, epochs, learning_rate, L1, L2)
    tic;
    net.train(X_train, y_train, 4000, 0.005, 0.0, 0.002);
    training_time = toc;
    
    % Store model for evaluation
    models{idx} = net;
    disp(['Training completed in ', num2str(training_time, '%.2f'), ' seconds.']);
end

%% 3. Quantitative Evaluation & Generalization Check
disp(' ');
disp('--- 3. Performance Metrics Evaluation ---');

for idx = 1:num_experiments
    net = models{idx};
    desc = architectures{idx, 3};
    
    % Predict on Train and Test sets
    pred_train = net.predict(X_train);
    pred_test  = net.predict(X_test);
    
    % Convert probabilities/continuous outputs to binary classifications (threshold = 0.5)
    class_train = pred_train >= 0.5;
    class_test  = pred_test >= 0.5;
    
    % Calculate Accuracy
    acc_train = sum(class_train == y_train) / length(y_train) * 100;
    acc_test  = sum(class_test == y_test) / length(y_test) * 100;
    
    % Calculate Mean Squared Error (MSE)
    mse_test = mean((pred_test - y_test).^2);
    
    fprintf('%s Results:\n', desc);
    fprintf('   • Train Accuracy: %.2f%%\n', acc_train);
    fprintf('   • Test Accuracy:  %.2f%%\n', acc_test);
    fprintf('   • Test Loss (MSE): %.4f\n', mse_test);
end

%% 4. Professional Visualization Suite
disp(' ');
disp('--- 4. Generating Visualization Dashboard ---');
figure('Name', 'UniLab Pro: Model Analysis', 'Position', [100, 100, 1200, 500]);

% Plot 1: Dataset & Decision Boundary for the Deep Model
subplot(1, 2, 1);
hold on;

% Create a dense grid to plot the decision boundary landscape
[gridX, gridY] = meshgrid(linspace(-1,1,100), linspace(-1,1,100));
grid_points = [gridX(:), gridY(:)];
grid_preds = models{2}.predict(grid_points); % Using the deep model's predictions
grid_preds_surf = reshape(grid_preds, size(gridX));

% Contour fill the decision boundary background
contourf(gridX, gridY, grid_preds_surf, [0 0.5 1], 'LineColor', 'none');
colormap(gca, [0.9 0.9 1; 1 0.9 0.9]); % Soft blue for Class 0, soft red for Class 1

% Plot original test data points over the boundary
scatter(X_test(y_test==0, 1), X_test(y_test==0, 2), 60, 'blue', 'filled', 'MarkerEdgeColor', 'w');
scatter(X_test(y_test==1, 1), X_test(y_test==1, 2), 60, 'red', 'filled', 'MarkerEdgeColor', 'w');

title('Deep MLP Test Data & Decision Boundary');
xlabel('Feature 1'); ylabel('Feature 2');
axis equal; grid on;
legend('Class 0 Space', 'Class 1 Space', 'Test Class 0', 'Test Class 1', 'Location', 'best');

% Plot 2: Selected Winning Architecture Visual
subplot(1, 2, 2);
plot_nn(architectures{2, 1});
title(['Champion Architecture: ', architectures{2, 3}]);

disp('Simulation and visualization complete.');