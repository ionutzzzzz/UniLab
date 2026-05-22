% 09_financial_risk_var.m
% UniLab Financial Engineering: Risk Analysis & Portfolio VaR

clear all;
close all;
clc;

disp('💰 UniLab Financial Risk Management');
disp('===================================');

%% 1. Value at Risk (VaR) - Historical Method
disp('--- 1. Portfolio Value at Risk (VaR) ---');
r_v = randn(1000, 1) * 0.01; 
p_v = 1000000;
a_v = 0.05; 

s_r = sort(r_v);
v_95 = -s_r(round(a_v * size(r_v, 1))) * p_v;

disp(['95% Confidence Daily VaR: $', num2str(v_95)]);

figure;
histogram(r_v * p_v, 50);
title('Portfolio P&L Distribution');
xlabel('Profit / Loss ($)'); ylabel('Frequency');
grid on;

%% 2. Monte Carlo Option Pricing (Greeks)
disp(' ');
disp('--- 2. Greeks Sensitivity Analysis ---');
S_v = 100.0; K_v = 105.0; T_v = 1.0; rv = 0.05;
v_r = linspace(0.1, 0.5, 41);
pr = zeros(1, size(v_r, 2));
for i = 1:size(v_r, 2)
    [c_p, p_p] = black_scholes(S_v, K_v, T_v, rv, v_r(i));
    pr(i) = c_p;
end

figure;
plot(v_r, pr, 'LineWidth', 2);
title('Call Option Price vs Volatility (Vega)');
xlabel('Volatility (\sigma)'); ylabel('Option Price ($)');
grid on;

%% 3. Stochastic Volatility Simulation
disp(' ');
disp('--- 3. Stock Path with Stochastic Vol ---');

function s_n = stock_step(s_c, p_p)
    s_n = s_c;
    dt = 0.01; r = 0.05;
    s_n.vol = max(0.01, s_c.vol + randn() * 0.01);
    drift = (r - 0.5 * s_n.vol^2) * dt;
    diffu = s_n.vol * sqrt(dt) * randn();
    s_n.S = s_c.S * exp(drift + diffu);
    s_n.h = [s_c.h; s_n.S];
end

function stock_draw(ax_o, s_d)
    plot(ax_o, s_d.h, 'g-', 'LineWidth', 1.5);
    title(ax_o, ['Simulated Stock Price ($', num2str(s_d.S), ')']);
end

st_f = struct('S', 100.0, 'vol', 0.2, 'h', [100.0]);
simulate('algorithm', 'step', @stock_step, 'draw', @stock_draw, 'state', st_f);

disp('Financial Risk Session Complete.');
