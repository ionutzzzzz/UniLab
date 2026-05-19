% 13_gui_pid_simulation.m
% Test the new interactive GUI PID simulator with a StateSpace model

disp('Starting PID Simulator...');

% Define a state-space model for a simple mass-spring-damper
% A = [0 1; -k/m -b/m], B = [0; 1/m], C = [1 0], D = [0]
m = 1.0;
k = 2.0;
b = 0.5;

A = [0 1; -k/m -b/m];
B = [0; 1/m];
C = [1 0];
D = [0];

sys = ss(A, B, C, D);

% Launch the interactive simulation GUI
simulate(sys, 'input', 'square', 'kp', 15.0, 'ki', 5.0, 'kd', 1.0);

disp('Simulation closed.');