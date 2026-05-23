% 51_electrical_grid_management.m
% UniLab Electrical Engineering: Economic Dispatch & Power Flow Analysis

clear all;
clc;

disp('⚡ UniLab Electrical Grid Management');
disp('====================================');

%% 1. Economic Dispatch (ED)
disp('--- 1. Economic Dispatch: Minimizing Generation Cost ---');
% Costs for 3 thermal units: C = a*P^2 + b*P + c
% [a, b, c]
costs = [0.004, 5.3, 500;
         0.006, 5.5, 400;
         0.009, 5.8, 200];

P_min = [100; 100; 50];
P_max = [400; 350; 250];
P_demand = 600; % Total system demand (MW)

P_gen = economic_dispatch(costs, P_min, P_max, P_demand);

disp('Optimal Generation Allocation:');
for i = 1:size(P_gen, 1)
    fprintf('  Unit %d: %.2f MW\n', i, P_gen(i));
end
fprintf('  Total:  %.2f MW (Demand: %d MW)\n', sum(P_gen), P_demand);

%% 2. Power Flow Analysis (Newton-Raphson / Gauss-Seidel)
disp(' ');
disp('--- 2. Load Flow Analysis: 2-Bus System ---');
% Define branches: [from, to, R, L, C]
% Resistance, Inductance, Capacitance (simplified values)
branches = [1, 2, 0.02, 0.04, 0.01]; 
Ybus = power_analyze(2, branches);

disp('System Y-Bus Matrix (2x2):');
disp(Ybus);

% System states
% Bus 1: Slack (V=1.0, delta=0)
% Bus 2: PQ Bus
P_gen_flow = [P_demand; 0]; % Slack supplies total
Q_gen_flow = [100; 0];
P_load_flow = [0; P_demand]; % Load at Bus 2
Q_load_flow = [0; 50];

V_init = [1.0; 1.0];
delta_init = [0.0; 0.0];

[V, delta, P_flow, Q_flow] = power_loadflow(Ybus, P_gen_flow, Q_gen_flow, P_load_flow, Q_load_flow, V_init, delta_init);

disp('Bus Voltages and Angles:');
for i = 1:length(V)
    fprintf('  Bus %d: V = %.4f pu, Angle = %.4f rad\n', i, V(i), delta(i));
end

%% 3. PWM and Motor Efficiency (Preview)
disp(' ');
disp('--- 3. Space Vector PWM Duty Cycles ---');
v_alpha = 0.8; v_beta = 0.4; v_dc = 1.0; fs = 10000;
duty_cycles = svpwm(v_alpha, v_beta, v_dc, fs);

disp('SVPWM Phase Duty Cycles (Ta, Tb, Tc):');
disp(duty_cycles(1, :));

disp('Grid Management Simulation Complete.');
