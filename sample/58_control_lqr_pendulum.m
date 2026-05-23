% 58_control_lqr_pendulum.m
% UniLab Control Systems: Linear Quadratic Regulator (LQR) for Inverted Pendulum

clear all;
clc;

disp('🕹️ UniLab Optimal Control: LQR Pendulum');
disp('=======================================');

%% 1. System Modeling (Linearized State-Space)
disp('--- 1. Linearized State-Space Model ---');
% Inverted pendulum on a cart
% States: [position, velocity, angle, angular_velocity]
% Parameters
m = 0.1;   % Mass of pendulum (kg)
M = 1.0;   % Mass of cart (kg)
L = 0.5;   % Length to pendulum CG (m)
g = 9.81;  % Gravity (m/s^2)
d = 0.1;   % Friction (N/m/s)

% Derived denominator
det_val = L * (M + m);

% A matrix (4x4)
A = [0, 1, 0, 0;
     0, -d/M, -m*g/M, 0;
     0, 0, 0, 1;
     0, -d/(M*L), (M+m)*g/(M*L), 0];

% B matrix (4x1)
B = [0; 1/M; 0; 1/(M*L)];

disp('System A matrix:');
disp(A);
disp('System B matrix:');
disp(B);

%% 2. Controllability Check
disp('--- 2. Controllability Check ---');
Co = ctrb(A, B);
rank_Co = matrix_rank_approx(Co);

fprintf('Controllability Matrix Rank: %d\n', rank_Co);
if rank_Co == 4
    disp('Status: System is Fully Controllable.');
else
    disp('Status: System is NOT Controllable.');
end

%% 3. LQR Controller Design
disp('--- 3. LQR Weight Tuning ---');
% Q: State penalty (penalize angle and position)
Q = diag([1, 1, 10, 1]);
% R: Control effort penalty
R = 0.01;

[K, P, E] = lqr(A, B, Q, R);

disp('Optimal LQR Gain K:');
disp(K);

%% 4. Closed-Loop Stability
disp('--- 4. Eigenvalue Analysis ---');
A_cl = A - B * K;
eig_cl = eig(A_cl);

disp('Closed-Loop Eigenvalues:');
disp(eig_cl);

if all(real(eig_cl) < 0)
    disp('Result: Closed-loop system is ASYMPTOTICALLY STABLE.');
else
    disp('Result: System remains unstable.');
end

%% 5. Simulation (Initial Condition Response)
disp('--- 5. Initial Condition Response ---');
x0 = [0; 0; 0.1; 0]; % 0.1 rad (~5.7 deg) initial tilt
t_vec = linspace(0, 5, 100);

% Close-loop sys: dx/dt = (A - BK)x
f_cl = @(t, x) (A - B * K) * x;
[T, Y] = ode45_custom(@(t, y) (A - B * K) * y(:), [0, 5], x0);

figure;
subplot(2, 1, 1);
plot(T, Y(:, 1), 'b-', 'LineWidth', 2);
title('Cart Position (m)'); grid on;

subplot(2, 1, 2);
plot(T, Y(:, 3), 'r-', 'LineWidth', 2);
title('Pendulum Angle (rad)'); grid on;

disp('State-Space Optimal Control Simulation Complete.');
