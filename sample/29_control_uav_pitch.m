% 29_control_uav_pitch.m
% UniLab Control Systems: UAV Pitch Control & Stability Analysis

clear all;
clc;

disp('✈️ UniLab Aerospace Control Systems');
disp('====================================');

%% 1. UAV Pitch Dynamics (Transfer Function)
% Linearized pitch dynamics of a fixed-wing UAV
% G(s) = theta(s) / delta_e(s) = 1.15s + 0.17 / (s^3 + 0.74s^2 + 0.93s)
num = [1.15, 0.17];
den = [1, 0.74, 0.93, 0];
G_pitch = tf(num, den);

disp('UAV Pitch Transfer Function:');
disp(G_pitch);

% Check stability
disp('Routh-Hurwitz Stability Check:');
rt = routh_table(den);

%% 2. Open-Loop Response
disp('--- 2. Open-Loop Step Response ---');
[y_ol, t_ol] = step(G_pitch, 20);

figure;
subplot(2, 1, 1);
plot(t_ol, y_ol, 'r-', 'LineWidth', 2);
title('Open-Loop Pitch Response (Unstable/Integral behavior)');
xlabel('Time (s)'); ylabel('Pitch Angle (\theta)');
grid on;

%% 3. Closed-Loop PID Control
disp('--- 3. Closed-Loop PID Tuning ---');
% Simple PD Controller: K(s) = Kp + Kd*s
Kp = 1.2; Kd = 0.5;
K_ctrl = tf([Kd, Kp], [1]);

% Feedback system: T = KG / (1 + KG)
sys_open = series(K_ctrl, G_pitch);
sys_closed = feedback(sys_open, 1);

[y_cl, t_cl] = step(sys_closed, 15);

subplot(2, 1, 2);
plot(t_cl, y_cl, 'b-', 'LineWidth', 2); hold on;
plot([0, 15], [1, 1], 'k--'); % Setpoint
title('Closed-Loop Pitch Control (PD Controlled)');
xlabel('Time (s)'); ylabel('Pitch Angle (\theta)');
legend('Response', 'Setpoint');
grid on; hold off;

%% 4. Root Locus & Frequency Analysis
disp('--- 4. Stability Analysis ---');
figure;
subplot(1, 2, 1);
rlocus(sys_open);
title('Root Locus of Pitch Control');

subplot(1, 2, 2);
bode(sys_open);
title('Bode Plot (Open-Loop)');

%% 5. Interactive Simulation
disp(' ');
disp('--- 5. Real-time PID Tuning ---');
% Using the built-in control simulator
simulate(G_pitch, 'kp', 1.2, 'kd', 0.5, 'time', [0, 20], 'input', 'step');

disp('UAV Control Session Complete.');