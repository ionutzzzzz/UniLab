% 64_finance_black_litterman.m
% UniLab Financial Engineering: Black-Litterman Asset Allocation
% This script combines market equilibrium with subjective views for optimal allocation.

clear all;
clc;

disp('📊 UniLab Quantitative Finance: Black-Litterman');
disp('===============================================');

%% 1. Market Equilibrium (Prior)
disp('--- 1. Market Equilibrium Estimates ---');
% Universe: [US Stocks, International Stocks, Bonds]
market_weights = [0.45; 0.35; 0.20];
cov_matrix = [0.005, 0.002, 0.001;
              0.002, 0.008, 0.002;
              0.001, 0.002, 0.003];

risk_aversion = 2.5; % Lambda
% Equilibrium returns: PI = lambda * Sigma * w
prior_returns = risk_aversion * cov_matrix * market_weights;

disp('Market Equilibrium Returns (Prior):');
disp(prior_returns');

%% 2. Subjective Views (The "Litterman" part)
disp(' ');
disp('--- 2. Incorporating Investor Views ---');
% View 1: US Stocks will outperform International by 2%
% View 2: Bonds will yield 3% absolute
P = [1, -1, 0;  % Relative view
     0,  0, 1]; % Absolute view
Q = [0.02; 0.03];

% View uncertainty (Omega) - assumed proportional to variance
tau = 0.05;
Omega = diag(diag(P * (tau * cov_matrix) * P'));

%% 3. Black-Litterman Master Formula
disp('--- 3. Combined Return Distribution ---');
% BL Expected Returns calculation
term1 = inv(inv(tau * cov_matrix) + P' * inv(Omega) * P);
term2 = inv(tau * cov_matrix) * prior_returns + P' * inv(Omega) * Q;
bl_returns = term1 * term2;

disp('Black-Litterman Posterior Returns:');
disp(bl_returns');

%% 4. Optimization & Comparison
disp('--- 4. Optimal Allocation Comparison ---');
port = Portfolio();
port.AssetMean = bl_returns;
port.AssetCovar = cov_matrix;

% Traditional Markowitz would use bl_returns
weights_bl = estimateMaxSharpeRatio(port);

disp('Market Weights:');
disp(market_weights');
disp('Black-Litterman Optimal Weights:');
disp(weights_bl);

% Visualize change in allocation
figure;
subplot(1, 2, 1);
bar_plot(market_weights(:));
title('Market Equilibrium Weights');

subplot(1, 2, 2);
bar_plot(weights_bl(:));
title('Black-Litterman Optimal Weights');

disp('Black-Litterman Analysis Complete.');
