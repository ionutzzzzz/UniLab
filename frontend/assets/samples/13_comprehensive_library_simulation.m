% 13_comprehensive_library_simulation.m
% UniLab Comprehensive Library Simulation
% Demonstrates functions across Math, ML, Stats, Control, Signal, and Viz libraries.

clear all;
clc;

disp('🌟 UniLab Comprehensive Library Simulation 🌟');
disp('===============================================');

%% 1. Mathematics & Statistics
disp('--- 1. Mathematics & Statistics ---');
% Generate some data
t = linspace(0, 10, 100);
signal_pure = sin(2 * t) + 0.5 * cos(5 * t);
noise = randn(1, 100) * 0.2;
signal_noisy = signal_pure + noise;

% Stats
disp('Calculating statistics on noisy signal:');
sig_mean = mean(signal_noisy);
sig_std = std(signal_noisy);
sig_skew = skewness(signal_noisy);
sig_kurt = kurtosis(signal_noisy);
fprintf('Mean: %.3f, Std: %.3f, Skew: %.3f, Kurtosis: %.3f\n', sig_mean, sig_std, sig_skew, sig_kurt);

% Math: Moving average & Integration
smoothed_signal = moving_average(signal_noisy, 5);
integral_val = trapz_custom(smoothed_signal, t);
fprintf('Integral of smoothed signal: %.3f\n', integral_val);

% Math: Root finding
func = @(x) x^3 - 4*x^2 + x + 6;
dfunc = @(x) 3*x^2 - 8*x + 1;
root1 = newton_raphson(func, dfunc, 2, 1e-6, 100);
fprintf('Root of x^3 - 4x^2 + x + 6 starting at x=2 is: %.3f\n', root1);

%% 2. Signal Processing
disp(' ');
disp('--- 2. Signal Processing ---');
% FFT to find frequencies
Y = fft(signal_noisy);
L = length(signal_noisy);
P2 = abs(Y / L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = (0:(L/2)) / 10; % Assuming T=10 duration

% Filter design
[b, a] = butter(4, 0.2, 'low');
filtered_signal = filter(b, a, signal_noisy);

disp('Visualizing filtered signal vs noisy signal (first 20 pts):');
disp('Noisy:');
disp(signal_noisy(1:20));
disp('Filtered:');
disp(filtered_signal(1:20));

%% 3. Control Systems
disp(' ');
disp('--- 3. Control Systems ---');
% Define a transfer function H(s) = 1 / (s^2 + 2s + 1)
num = [1];
den = [1, 2, 1];
sys = tf(num, den);

% Step response
disp('Simulating step response:');
[y_step, t_step] = step(sys, 10);
disp('Step response final value:');
disp(y_step(end));

% Routh table for stability
disp('Routh-Hurwitz Stability Check for den = [1, 2, 1]:');
rt = routh_table(den);

%% 4. Machine Learning
disp(' ');
disp('--- 4. Machine Learning ---');
% Create synthetic dataset (Make blobs)
[X, y] = make_blobs(100, 2, 2, 1.5);

% Scale features
[X_scaled, min_val, max_val] = min_max_scale(X);

% Train/Test split
[X_train, X_test, y_train, y_test] = train_test_split(X_scaled, y, 0.2);

% Train Logistic Regression
disp('Training Logistic Regression Classifier...');
theta = logistic_regression_train(X_train, y_train - 1, 0.1, 500, 0);

% Predict and evaluate
preds = logistic_regression_predict(X_test, theta);
acc = accuracy(y_test - 1, preds);
fprintf('Model Accuracy on Test Set: %.2f%%\n', acc * 100);

% Confusion Matrix
cm = confusion_matrix(y_test, preds + 1, 2);
disp('Confusion Matrix:');
plot_matrix(cm);

%% 5. Visualization
disp(' ');
disp('--- 5. Visualization Suite ---');
% Scatter plot of ML data
disp('Visualizing ML Training Data (Feature 1 vs Feature 2):');
scatter_plot(X_train(:,1), X_train(:,2), 'Training Data');

% Area plot
disp('Visualizing area under a curve:');
x_area = linspace(0, 4*pi(), 50);
y_area = abs(sin(x_area));
area_plot(x_area, y_area);

disp('Comprehensive Library Simulation Complete.');