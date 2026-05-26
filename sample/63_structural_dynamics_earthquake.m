% 63_structural_dynamics_earthquake.m
% UniLab Structural Engineering: Multi-Degree-of-Freedom Building Dynamics
% This script simulates a 3-story building response to a seismic impulse.

clear all;
close all;
clc;

disp('🏙️ UniLab Structural Dynamics Lab');
disp('==================================');

%% 1. Building Model (Mass & Stiffness)
disp('--- 1. 3-Story Building Model ---');
m = 10000; % Story mass (kg)
k = 5e6;   % Inter-story stiffness (N/m)

% Mass Matrix
M = diag([m, m, m]);
% Stiffness Matrix
K = [ 2*k, -k,   0;
     -k,    2*k, -k;
      0,   -k,    k];

disp('Global Stiffness Matrix K:');
disp(K);

%% 2. Modal Analysis
disp('--- 2. Natural Frequencies & Mode Shapes ---');
% Solve eigenvalue problem: K*phi = omega^2 * M*phi
[V, D] = eig(inv(M) * K);
eigenvalues = diag(D);
[omega_sq, sort_idx] = sort(eigenvalues);
omega = sqrt(omega_sq);
freq_hz = omega / (2 * pi());
modes = V(:, sort_idx);

fprintf('Natural Frequencies (Hz):\n');
for i = 1:3
    fprintf('  Mode %d: %.2f Hz\n', i, freq_hz(i));
end

%% 3. Seismic Response Simulation
disp(' ');
disp('--- 3. Earthquake Impulse Response ---');
% State vector y = [x1, x2, x3, v1, v2, v3]
% Acceleration a = M^-1 * (-K*x + F_ground)

y0 = zeros(6, 1); % Initially at rest
t_span = [0, 5];

% Seismic force (Impulse at the base)
f_seismic = @(t, y) [y(4:6); inv(M) * (-K * y(1:3))];

% Simulating ground motion as an initial velocity for all floors
y0(4:6) = 2.0; % 2 m/s sudden ground shift

[T, Y] = ode45_custom(f_seismic, t_span, y0);

figure;
plot(T, Y(:, 1), 'b-', 'LineWidth', 1.5); hold on;
plot(T, Y(:, 2), 'g-', 'LineWidth', 1.5);
plot(T, Y(:, 3), 'r-', 'LineWidth', 1.5);
title('Building Seismic Response (Story Displacements)');
xlabel('Time (s)'); ylabel('Relative Displacement (m)');
legend('Floor 1', 'Floor 2', 'Floor 3');
grid on;

%% 4. Interactive Modal Visualization
disp(' ');
disp('--- 4. Interactive Mode Shape Sweep ---');

function s_n = bldg_step(s_c, p_p)
    s_n = s_c;
    s_n.t = s_c.t + 0.05;
    % Animate first mode oscillation
    s_n.pos = s_c.mode * sin(2 * pi * s_c.f * s_n.t);
end

function bldg_draw(ax, s)
    floors = [0; s.pos(:)];
    y_coords = [0, 1, 2, 3];
    plot(ax, floors, y_coords, 'bo-', 'LineWidth', 4, 'MarkerSize', 10);
    title(ax, ['Mode 1 Animation (', num2str(s.f), ' Hz)']);
    xlim(ax, [-1, 1]); ylim(ax, [-0.5, 3.5]); grid(ax, 'on');
    ylabel(ax, 'Floor Number');
end

st_b = struct('t', 0, 'pos', [0;0;0], 'mode', modes(:,1), 'f', freq_hz(1));
simulate('algorithm', 'step', @bldg_step, 'draw', @bldg_draw, 'state', st_b);

disp('Structural Dynamics Session Complete.');
