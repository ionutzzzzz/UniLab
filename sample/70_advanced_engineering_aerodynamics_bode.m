% 70_advanced_engineering_aerodynamics_bode.m
% UniLab Complex Engineering Systems: Control Systems Tuning, Bode Analysis & Aerodynamics
% This script models a complete control loop tuning sequence for a mechanical plant,
% plots the frequency response using Bode analysis, evaluates airfoil lift/drag forces,
% and simulates projectile flight trajectories.

clear all;
close all;
clc;

disp('🏗️ UniLab Complex Engineering Systems Analysis');
disp('===============================================');

%% 1. PID Controller Tuning for Plant transfer function
disp('Tuning PID parameters using Ziegler-Nichols open-loop rules...');
% Plant characteristics: static gain K=2.5, time constant T=1.8s, dead-time L=0.25s
tuning_zn = engineering.pid_tuning(2.5, 1.8, 0.25, 'ziegler-nichols');
tuning_cc = engineering.pid_tuning(2.5, 1.8, 0.25, 'cohen-coon');

fprintf('  Ziegler-Nichols Tuning:\n');
fprintf('    Kp: %.4f | Ki: %.4f | Kd: %.4f\n', tuning_zn.Kp, tuning_zn.Ki, tuning_zn.Kd);
fprintf('  Cohen-Coon Tuning:\n');
fprintf('    Kp: %.4f | Ki: %.4f | Kd: %.4f\n', tuning_cc.Kp, tuning_cc.Ki, tuning_cc.Kd);

%% 2. Control Systems Bode Frequency Response
disp('Computing Bode frequency response for 2nd order system...');
% H(s) = 50 / (s^2 + 6s + 25)
num = [50.0];
den = [1.0, 6.0, 25.0];
[w, magnitude_db, phase_deg] = engineering.control_bode_plot(num, den);

% Find resonance frequency and peak gain
[max_mag, peak_idx] = max(magnitude_db);
fprintf('  Resonant Peak Gain:   %.2f dB\n', max_mag);
fprintf('  Resonant Frequency:   %.2f rad/s\n', w(peak_idx));

figure;
plot(w, magnitude_db, 'c-', 'LineWidth', 1.5);
title('Bode Magnitude Response H(s) = 50 / (s^2 + 6s + 25)');
xlabel('Frequency (rad/s)');
ylabel('Magnitude (dB)');
grid on;

figure;
plot(w, phase_deg, 'r-', 'LineWidth', 1.5);
title('Bode Phase Response');
xlabel('Frequency (rad/s)');
ylabel('Phase (deg)');
grid on;

%% 3. Airfoil Aerodynamics Lift & Drag Forces
disp('Calculating airfoil aerodynamic coefficients across flow velocities...');
velocities = 10:10:100; % velocity from 10m/s to 100m/s
lifts = [];
drags = [];

for v = velocities
    forces = engineering.aerodynamics_lift_drag(1.225, v, 12.0, 0.6, 0.04);
    lifts = [lifts; forces.lift_n];
    drags = [drags; forces.drag_n];
end

% Print lift-to-drag statistics
efficiency = lifts ./ drags;
fprintf('  Airfoil Lift-to-Drag Ratio (L/D): %.2f\n', mean(efficiency));
fprintf('  Max Lift Force at 100 m/s:      %.2f N\n', max(lifts));

figure;
plot(velocities, lifts, 'y-o', velocities, drags, 'c-*', 'LineWidth', 1.5);
title('Aerodynamic Forces: Lift (Yellow) vs Drag (Cyan)');
xlabel('Velocity (m/s)');
ylabel('Force (N)');
grid on;

%% 4. Projectile Motion with elevation
disp('Simulating projectile trajectory (elevation h0=10m, v0=30m/s, angle=35)...');
[t_proj, x_proj, y_proj, flight_time, max_height, total_range] = engineering.projectile_motion(30.0, 35.0, 10.0, 9.81);
fprintf('  Flight Time: %.2f s\n', flight_time);
fprintf('  Max Height:  %.2f m\n', max_height);
fprintf('  Total Range: %.2f m\n', total_range);

figure;
plot(x_proj, y_proj, 'w-', 'LineWidth', 1.5);
title('2D Projectile Trajectory (with initial height)');
xlabel('Range (m)');
ylabel('Altitude (m)');
grid on;

disp('Engineering analysis completed successfully.');
