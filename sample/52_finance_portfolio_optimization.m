% 52_finance_portfolio_optimization.m
% UniLab Financial Engineering: Portfolio Risk & Efficient Frontier

clear all;
clc;

disp('💰 UniLab Portfolio Optimization');
disp('================================');

%% 1. Portfolio Definition
disp('--- 1. Defining Assets and Expected Returns ---');
% Assume 4 assets with different risk/return profiles
asset_means = [0.08, 0.12, 0.05, 0.15]; % Expected annual returns
asset_covar = [0.005, 0.002, 0.001, 0.003;
               0.002, 0.008, 0.002, 0.004;
               0.001, 0.002, 0.003, 0.001;
               0.003, 0.004, 0.001, 0.012];

% Initialize Portfolio object
port = Portfolio();
port.AssetMean = asset_means;
port.AssetCovar = asset_covar;

disp('Portfolio Expected Asset Returns:');
disp(asset_means);
disp('Portfolio Covariance Matrix:');
disp(asset_covar);

%% 2. Optimization Targets
disp('--- 2. Optimization: Min Variance and Max Sharpe ---');

% Find Global Minimum Variance Portfolio
w_min_var = estimateMinVariance(port);
% Find Maximum Sharpe Ratio Portfolio
w_max_sharpe = estimateMaxSharpeRatio(port);

disp('Weights for Global Minimum Variance Portfolio:');
disp(w_min_var);
disp('Weights for Maximum Sharpe Ratio Portfolio:');
disp(w_max_sharpe);

%% 3. Efficient Frontier
disp(' ');
disp('--- 3. Efficient Frontier Calculation ---');
% Estimate 10 points on the efficient frontier
num_points = 10;
frontier_weights = estimateFrontier(port, num_points);

disp(['Estimated ', num2str(num_points), ' points on the Frontier.']);

% Visualization using the library function
plotFrontier(port);

%% 4. Additional Analysis: Option Pricing for Hedging
disp(' ');
disp('--- 4. Derivatives: Black-Scholes Delta Hedging ---');
S = 100; K = 100; T = 0.25; r = 0.03; sigma = 0.2;
d_call = blsdelta(S, K, T, r, sigma, 'call');
d_put = blsdelta(S, K, T, r, sigma, 'put');

fprintf('Call Option Delta: %.4f (Buy shares to hedge)\n', d_call);
fprintf('Put Option Delta:  %.4f (Sell shares to hedge)\n', d_put);

disp('Portfolio Optimization Analysis Complete.');
