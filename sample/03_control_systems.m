% 03_control_systems.m
% UniLab Control Engineering: Stability, Bode Plots, and PID Design

disp('⚙️ UniLab Control Engineering Studio');
disp('=====================================');

%% 1. Plant Modeling & Stability
disp('--- 1. Transfer Function & Stability ---');
% Plant G(s) = 1 / (s^3 + 3s^2 + 3s + 1)
G = tf([1], [1, 3, 3, 1]);
disp('Plant Transfer Function:');
disp(G);

% Routh-Hurwitz Stability Table
routh_table([1, 3, 3, 1]);

%% 2. Frequency Domain Analysis
disp(' ');
disp('--- 2. Frequency Domain ---');
disp('Computing Bode frequency response...');
bode(G);
title('Open-Loop Frequency Response');

%% 3. Closed-Loop PID Design
disp(' ');
disp('--- 3. Interactive PID Tuning ---');
% Define a standard second-order system for the GUI
% s^2 + 2*zeta*wn*s + wn^2
sys = tf([1], [1, 1, 1]);

% Initial tuning parameters
kp = 10.0; ki = 2.0; kd = 0.5;

function pid_init()
    uilabel('info', 'Adjust sliders to minimize overshoot.');
    uibutton('Reset Gains', @() uiset('Kp', 1.0));
end

disp('Launching PID Simulator with Square Wave input...');
simulate(sys, 'input', 'square', 'kp', kp, 'ki', ki, 'kd', kd, 'on_init', @pid_init);

disp(' ');
disp('Control Engineering Studio Complete.');
