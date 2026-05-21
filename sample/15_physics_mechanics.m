% 15_physics_mechanics.m
% Demonstrates classical mechanics, kinematics, and energy conservation

disp('⚙️ UniLab Mechanics Lab');
disp('=======================');

disp('--- 1. Projectile Motion with Air Resistance ---');
m = 0.145; % Mass of a baseball (kg)
v0 = 40.0; % Initial velocity (m/s)
theta = deg2rad_custom(45); % Launch angle

v0_x = v0 * cos(theta);
v0_y = v0 * sin(theta);
a_y = -9.81; % Gravity

% Time of flight calculation (ignoring air resistance for time)
t_flight = -2 * v0_y / a_y;
t = linspace(0, t_flight, 50);

x_t = kinematic_eq2(v0_x, 0, t);
y_t = kinematic_eq2(v0_y, a_y, t);

figure; plot(x_t, y_t, 'r-', 'LineWidth', 2);
title('Baseball Projectile Motion'); xlabel('Distance (m)'); ylabel('Height (m)'); grid on;

disp('--- 2. Energy and Momentum ---');
K = energy_kinetic(m, v0);
p = momentum(m, v0);
fprintf('Initial Kinetic Energy of the baseball: %.2f Joules
', K);
fprintf('Initial Momentum of the baseball: %.2f kg*m/s
', p);
