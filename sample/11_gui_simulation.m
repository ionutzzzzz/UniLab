% 11_gui_simulation.m
% Test the new interactive GUI simulation

disp('Starting Control System Simulator...');

% Define a transfer function (mass-spring-damper or similar)
% G(s) = 1 / (s^2 + 2s + 1)
sys = tf([1], [1, 2, 1]);

% Launch the interactive simulation GUI
simulate(sys, 'input', 'step');

disp('Simulation closed.');
