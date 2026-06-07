% 42_control_system_margins.m
% UniLab Control Systems: Stability Margins & Transients

clear all;
clc;

disp('🎛️ UniLab Control Stability Lab');
disp('================================');

%% 1. Open-Loop System Definition
disp('--- 1. System Transfer Function ---');
% G(s) = 10 / (s^3 + 3s^2 + 2s)
num = [10];
den = [1, 3, 2, 0];
sys = tf(num, den);

disp('G(s) =');
disp(sys);

%% 2. Stability Analysis (Margis)
disp('--- 2. Frequency Domain Margins ---');
gm = gain_margin_calc(sys);
pm = phase_margin_calc(sys);

fprintf('Gain Margin:  %.2f (dB if converted)\n', gm);
fprintf('Phase Margin: %.2f degrees\n', pm);

if pm > 0 && gm > 1
    disp('Result: System is STABLE in closed loop.');
else
    disp('Result: System is UNSTABLE in closed loop.');
end

%% 3. Closed-Loop Performance
disp(' ');
disp('--- 3. Transient Response Estimation ---');
% Using a simple second-order approximation based on overshoot
OS_percent = 20.0;
zeta = damping_ratio_calc(OS_percent);
wn = 2.5; % assumed natural frequency

ts = settling_time_calc(zeta, wn, 0.02);
tr = rise_time_calc(zeta, wn);

fprintf('For %.0f%% Overshoot:\n', OS_percent);
fprintf('  Damping Ratio (zeta): %.3f\n', zeta);
fprintf('  Estimated Rise Time:  %.3f s\n', tr);
fprintf('  Estimated Settling Time: %.3f s\n', ts);

%% 4. PID Control Loop
disp(' ');
disp('--- 4. Interactive PID Stability ---');
% CheckDen for DEN=[1 3 2 0] with P controller K=1
% 1 + K*G = 1 + K*(10/(s^3+3s^2+2s)) = s^3+3s^2+2s+10K
Kp = 1.0;
den_cl = [1, 3, 2, 10*Kp];
disp('Routh Table for Closed Loop (K=1):');
rt = routh_table(den_cl);

disp('Control Stability Analysis Complete.');