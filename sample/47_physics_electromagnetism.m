% 47_physics_electromagnetism.m
% UniLab Physics: Electromagnetism and Optics

clear all;
clc;

disp('⚡ UniLab Physics: Electromagnetism & Optics');
disp('===========================================');

disp('--- 1. Electric and Magnetic Fields ---');
q_electron = -1.602e-19; % Coulombs
k_coulomb = 8.987e9; % Coulomb's Constant (N m^2 / C^2)
r = 0.05; % Distance: 5 cm

E = electric_field(k_coulomb, q_electron, r);
fprintf('Electric field magnitude at 5cm from an electron: %.4e N/C\n', E);

% Magnetic Force on a moving charge
v = 3e6; % Velocity: 3,000 km/s
B = 1.5; % Magnetic field: 1.5 Tesla
theta = deg2rad_custom(90); % Moving perpendicularly
F_m = magnetic_force(q_electron, v, B, theta);
fprintf('Magnetic force on electron moving at 3000 km/s in 1.5T field: %.4e N\n', F_m);

disp(' ');
disp('--- 2. Optics: Snell''s Law & Polarization ---');
n_air = 1.00029;
n_glass = 1.52;
theta_inc = deg2rad_custom(45); % 45 degree incidence

theta_ref = snells_law(n_air, theta_inc, n_glass);
fprintf('Angle of refraction for 45 deg incidence (Air -> Glass): %.2f deg\n', rad2deg_custom(theta_ref));

theta_B = brewster_angle(n_air, n_glass);
fprintf('Brewster''s angle for total polarization (Air -> Glass): %.2f deg\n', rad2deg_custom(theta_B));

% Critical angle for total internal reflection (Glass to Air)
theta_c = total_internal_reflection_angle(n_glass, n_air);
fprintf('Critical angle for total internal reflection (Glass -> Air): %.2f deg\n', rad2deg_custom(theta_c));

disp('Electromagnetism and Optics simulation complete.');