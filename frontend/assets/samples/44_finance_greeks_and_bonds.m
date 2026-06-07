% 44_finance_greeks_and_bonds.m
% UniLab Financial Engineering: Option Greeks & Bond Pricing

clear all;
clc;

disp('💸 UniLab Quantitative Finance');
disp('================================');

%% 1. Option Greeks Profile
disp('--- 1. Black-Scholes Greeks ---');
S = 100;    % Spot price
K = 105;    % Strike price
T = 0.5;    % Time to maturity (6 months)
r = 0.05;   % Risk-free rate
sigma = 0.2;% Volatility

% Calculate Greeks for a Call
delta = black_scholes_delta(S, K, T, r, sigma, 'call');
gamma = black_scholes_gamma(S, K, T, r, sigma);
vega = black_scholes_vega(S, K, T, r, sigma);
theta = black_scholes_theta(S, K, T, r, sigma, 'call');
rho = black_scholes_rho(S, K, T, r, sigma, 'call');

fprintf('Option Metrics (S=$%d, K=$%d, T=%.1f):\n', S, K, T);
fprintf('  Delta: %.4f\n', delta);
fprintf('  Gamma: %.4f\n', gamma);
fprintf('  Vega:  %.4f\n', vega);
fprintf('  Theta: %.4f per year\n', theta);
fprintf('  Rho:   %.4f\n', rho);

%% 2. Bond Pricing and Sensitivity
disp(' ');
disp('--- 2. Coupon Bond valuation ---');
par = 1000;
coupon_rate = 0.06;
ytm = 0.04;
years = 10;

price = bond_price_calc(par, coupon_rate, ytm, years);
fprintf('10-year Bond Price (6%% coupon, 4%% YTM): $%.2f\n', price);

%% 3. Yield to Maturity (YTM) Estimation
disp(' ');
disp('--- 3. YTM Approximation ---');
market_price = 950.0;
ytm_approx = bond_yield_to_maturity(market_price, par, coupon_rate, years);
fprintf('Approximate YTM for market price $%.2f: %.2f%%\n', market_price, ytm_approx * 100);

%% 4. Time Value of Money
disp(' ');
disp('--- 4. Annuity Future Value ---');
pmt = 100; % Monthly deposit
rate_annual = 0.08;
n_months = 12 * 5; % 5 years

total_fv = annuity_fv(pmt, rate_annual/12, n_months);
fprintf('Future Value of $%d/month for 5 years at 8%%: $%.2f\n', pmt, total_fv);

disp('Financial Engineering Analysis Complete.');