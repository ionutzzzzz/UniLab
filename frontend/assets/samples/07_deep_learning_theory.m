% 07_deep_learning_theory.m
% UniLab Deep Learning: Function Approximation and Theory

clear all;
close all;
clc;

disp('🧠 UniLab Deep Learning: Function Approximation');
disp('==============================================');

%% 1. Function Approximation with Neural Network
disp('--- 1. Fitting f(x) = sin(x) + 0.5*sin(2x) + 1/3*sin(3x) ---');

% Data Generation
X = linspace(0, 2*pi, 200)';

y = sin(X) + 0.5*sin(2*X) + (1/3)*sin(3*X);

% Normalization for Sigmoid activation
X_norm = X / (2*pi);
y_min = min(y); y_max = max(y);
y_norm = (y - y_min) / (y_max - y_min);

% Train/Validation Split (80/20)
indices = randperm(200);
train_idx = indices(1:160);
val_idx = indices(161:200);

X_train = reshape(X_norm(train_idx), 160, 1); 
y_train = reshape(y_norm(train_idx), 160, 1);
X_val = reshape(X_norm(val_idx), 40, 1); 
y_val = reshape(y_norm(val_idx), 40, 1);

% Manual Neural Network (1 -> 64 -> 64 -> 1)
% Xavier Initialization
W1 = randn(1, 64) * sqrt(1/1); b1 = zeros(1, 64);
W2 = randn(64, 64) * sqrt(1/64); b2 = zeros(1, 64);
W3 = randn(64, 1) * sqrt(1/64); b3 = zeros(1, 1);

% RMSprop parameters
lr = 0.002;
beta = 0.9;
eps = 1e-8;
mW1 = zeros(size(W1)); mb1 = zeros(size(b1));
mW2 = zeros(size(W2)); mb2 = zeros(size(b2));
mW3 = zeros(size(W3)); mb3 = zeros(size(b3));

epochs = 100;
train_loss_hist = zeros(epochs, 1);
val_loss_hist = zeros(epochs, 1);

for epoch = 1:epochs
    % Forward Pass (Train)
    z1 = X_train * W1 + b1;
    a1 = tanh(z1); 
    z2 = a1 * W2 + b2;
    a2 = tanh(z2);
    z3 = a2 * W3 + b3;
    a3 = z3; % Linear output for regression
    
    % Loss (MSE)
    err = a3 - y_train;
    train_loss = mean(err.^2);
    train_loss_hist(epoch) = train_loss;
    
    % Forward Pass (Validation)
    vz1 = X_val * W1 + b1; va1 = tanh(vz1);
    vz2 = va1 * W2 + b2; va2 = tanh(vz2);
    vz3 = va2 * W3 + b3; va3 = vz3;
    val_loss = mean((va3 - y_val).^2);
    val_loss_hist(epoch) = val_loss;
    
    % Backward Pass
    d_z3 = 2 * err / length(X_train);
    d_W3 = a2' * d_z3;
    d_b3 = sum(d_z3, 1);
    
    d_a2 = d_z3 * W3';
    d_z2 = d_a2 .* (1 - a2.^2);
    d_W2 = a1' * d_z2;
    d_b2 = sum(d_z2, 1);
    
    d_a1 = d_z2 * W2';
    d_z1 = d_a1 .* (1 - a1.^2);
    d_W1 = X_train' * d_z1;
    d_b1 = sum(d_z1, 1);
    
    % Update (RMSprop)
    mW3 = beta * mW3 + (1-beta) * d_W3.^2;
    mb3 = beta * mb3 + (1-beta) * d_b3.^2;
    W3 = W3 - lr * d_W3 ./ (sqrt(mW3) + eps);
    b3 = b3 - lr * d_b3 ./ (sqrt(mb3) + eps);
    
    mW2 = beta * mW2 + (1-beta) * d_W2.^2;
    mb2 = beta * mb2 + (1-beta) * d_b2.^2;
    W2 = W2 - lr * d_W2 ./ (sqrt(mW2) + eps);
    b2 = b2 - lr * d_b2 ./ (sqrt(mb2) + eps);
    
    mW1 = beta * mW1 + (1-beta) * d_W1.^2;
    mb1 = beta * mb1 + (1-beta) * d_b1.^2;
    W1 = W1 - lr * d_W1 ./ (sqrt(mW1) + eps);
    b1 = b1 - lr * d_b1 ./ (sqrt(mb1) + eps);
    
    if mod(epoch, 5000) == 0
        disp(['Epoch ', num2str(epoch), ': Train Loss = ', num2str(train_loss), ', Val Loss = ', num2str(val_loss)]);
    end
end

% Final Prediction
z1_f = X_norm * W1 + b1; a1_f = tanh(z1_f);
z2_f = a1_f * W2 + b2; a2_f = tanh(z2_f);
y_pred_norm = a2_f * W3 + b3;
y_pred = y_pred_norm * (y_max - y_min) + y_min;

% Final Prediction
z1_f = X_norm * W1 + b1; a1_f = tanh(z1_f);
z2_f = a1_f * W2 + b2; a2_f = tanh(z2_f);
y_pred_norm = a2_f * W3 + b3;
y_pred = y_pred_norm * (y_max - y_min) + y_min;

% Plotting Results
disp(' ');
disp('--- 2. Visualization ---');
figure;
subplot(2, 1, 1);
plot(X, y, 'b', 'LineWidth', 2); hold on;
plot(X, y_pred, 'r--', 'LineWidth', 2);
title('Neural Network Function Fit: sin(x) + 0.5*sin(2x) + 1/3*sin(3x)');
legend('Actual Data', 'NN Prediction');
grid on;

subplot(2, 1, 2);
plot(1:epochs, train_loss_hist, 'b'); hold on;
plot(1:epochs, val_loss_hist, 'r');
title('Training vs Validation Loss');
xlabel('Epochs'); ylabel('MSE Loss');
legend('Train Loss', 'Val Loss');
grid on;

disp('Deep Learning Theory Session Complete.');
