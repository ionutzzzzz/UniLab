% 09_financial_engineering.m
% UniLab Financial Engineering: Black-Scholes and Monte Carlo Paths

disp('💰 UniLab Financial Engineering Desk');
disp('====================================');

%% 1. Option Pricing (Black-Scholes)
disp('--- 1. Black-Scholes Pricing ---');
S = 100;    % Spot price
K = 105;    % Strike price
T = 1.0;    % Time to maturity (1 year)
r = 0.05;   % Risk-free rate
sigma = 0.2;% Volatility

[call, put] = black_scholes(S, K, T, r, sigma);
disp(['Theoretical Call Price: $', num2str(call)]);
disp(['Theoretical Put Price:  $', num2str(put)]);

%% 2. Monte Carlo Stock Paths
disp(' ');
disp('--- 2. Monte Carlo Simulation ---');
N_paths = 10;
N_steps = 1000;
dt = T/N_steps;

% Geometric Brownian Motion
paths = zeros(N_steps+1, N_paths);
paths(1, :) = S;

for p = 1:N_paths
    for t_idx = 1:N_steps
        drift = (r - 0.5 * sigma^2) * dt;
        diffusion = sigma * sqrt(dt) * randn();
        paths(t_idx+1, p) = paths(t_idx, p) * exp(drift + diffusion);
    end
end

disp(['Simulated ', num2str(N_paths), ' random price paths. opening Plot...']);
plot(paths);
title('Monte Carlo: Price Path Predictions');
xlabel('Steps'); ylabel('Price ($)');
grid('on');

disp(' ');
disp('Financial Desk Session Complete.');
