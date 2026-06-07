% 26_statistical_distributions.m
% Demonstrates statistical variance, covariance, and probability densities

clear all;
close all;
clc;

disp('📊 UniLab Statistical Distributions');
disp('===================================');

disp('--- 1. Descriptive Statistics ---');
data_x = [12, 15, 14, 19, 22, 24, 21, 18, 16];
data_y = [50, 55, 52, 65, 75, 80, 72, 60, 58];

var_x = variance_custom(data_x);
cov_xy = covariance_custom(data_x, data_y);

fprintf('Variance of Dataset X: %.2f
', var_x);
fprintf('Covariance between X and Y: %.2f
', cov_xy);

disp('--- 2. Probability Density Functions ---');
x = linspace(-5, 5, 100);

% Normal Distribution
y_norm_1 = normal_pdf(x, 0, 1);
y_norm_2 = normal_pdf(x, 0, 2);

% Exponential Distribution (only defined for x >= 0)
x_pos = linspace(0, 5, 50);
y_exp = exponential_pdf(x_pos, 1.5);

figure;
subplot(1, 2, 1);
plot(x, y_norm_1, 'b-', 'LineWidth', 2); hold on;
plot(x, y_norm_2, 'r--', 'LineWidth', 2);
title('Normal PDF'); legend('\sigma=1', '\sigma=2'); grid on;

subplot(1, 2, 2);
plot(x_pos, y_exp, 'k-', 'LineWidth', 2);
title('Exponential PDF (\lambda=1.5)'); grid on;

disp('--- 3. Discrete Distributions ---');
% Poisson Distribution for rare events (e.g. server crashes)
lambda_events = 3.5;
fprintf('Probability of exactly 5 events when average is 3.5: %.4f
', poisson_probability(lambda_events, 5));
