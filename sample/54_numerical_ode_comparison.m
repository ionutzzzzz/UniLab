% 54_numerical_ode_comparison.m
% UniLab Numerical Methods: Comparative ODE Integration

clear all;
close all;
clc;

disp('🧮 UniLab ODE Integration Benchmark');
disp('====================================');

%% 1. Problem Definition: Simple Nonlinear Pendulum
disp('--- 1. Nonlinear Pendulum Dynamics ---');
% d2(theta)/dt2 + (g/L)sin(theta) = 0
% State vector y = [theta, omega]
% dy/dt = [omega, -(g/L)sin(theta)]

g = 9.81; L = 1.0;
f_pendulum = @(t, y) [y(2), -(g/L)*sin(y(1))];

% Initial conditions: 45 degree angle, zero velocity
y0 = [pi/4, 0.0];
t_span = [0, 10];
h = 0.1; % Relatively large step size to highlight error

%% 2. Integration with Different Solvers
disp('--- 2. Benchmarking Solvers (h=0.1s) ---');

% First-order: Euler
y_euler = euler_method(f_pendulum, t_span, y0, h);
% Second-order: Heun
y_heun = heun_method(f_pendulum, t_span, y0, h);
% Fourth-order: RK4
y_rk4 = runge_kutta_4(f_pendulum, t_span, y0, h);
% Multi-step: Adams-Bashforth 2
y_ab2 = adams_bashforth_2(f_pendulum, t_span, y0, h);

t_vec = t_span(1):h:t_span(2);

%% 3. Visualization
disp(' ');
disp('--- 3. Numerical Error and Convergence ---');
figure;
plot(t_vec, y_euler(:, 1), 'r--', 'LineWidth', 1); hold on;
plot(t_vec, y_heun(:, 1), 'g--', 'LineWidth', 1.5);
plot(t_vec, y_ab2(:, 1), 'm:', 'LineWidth', 1.5);
plot(t_vec, y_rk4(:, 1), 'b-', 'LineWidth', 2);
title('ODE Solver Comparison: Nonlinear Pendulum (\theta)');
xlabel('Time (s)'); ylabel('Angle (rad)');
legend('Euler (1st)', 'Heun (2nd)', 'Adams-Bashforth (2nd)', 'Runge-Kutta (4th)');
grid on;

% Energy Conservation Check (Hamiltonian)
% Total Energy E = 0.5*m*L^2*omega^2 + m*g*L*(1-cos(theta))
% We'll assume m=1, L=1 for energy profile
energy_rk4 = 0.5 * y_rk4(:, 2).^2 + g * (1 - cos(y_rk4(:, 1)));
energy_euler = 0.5 * y_euler(:, 2).^2 + g * (1 - cos(y_euler(:, 1)));

figure;
plot(t_vec, energy_rk4, 'b-', 'LineWidth', 2); hold on;
plot(t_vec, energy_euler, 'r--', 'LineWidth', 1);
title('Energy Conservation Profile');
xlabel('Time (s)'); ylabel('Energy (J)');
legend('RK4 (Stable)', 'Euler (Gains Energy)');
grid on;

disp('Numerical Analysis: RK4 remains stable while Euler diverges.');
disp('ODE Benchmark Session Complete.');
