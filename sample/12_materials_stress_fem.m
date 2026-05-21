% 12_materials_stress_fem.m
% UniLab Materials Science: Stress, Strain, and Finite Element Modeling

clear all;
clc;

disp('💎 UniLab Materials Science & FEA');
disp('==================================');

%% 1. Stress-Strain Curve (Elastic-Plastic)
disp('--- 1. Stress-Strain Behavior ---');
strain_vals = 0:0.001:0.1;
E_val = 200e9; % Young's Modulus (Pa)
yield_stress = 250e6;
stress_vals = zeros(size(strain_vals));

for i = 1:size(strain_vals, 2)
    s_linear = E_val * strain_vals(i);
    if s_linear < yield_stress
        stress_vals(i) = s_linear;
    else
        % Power law hardening
        stress_vals(i) = yield_stress + 500e6 * (strain_vals(i) - yield_stress/E_val)^0.5;
    end
end

figure;
plot(strain_vals, stress_vals / 1e6, 'b-', 'LineWidth', 2);
title('Stress-Strain Curve (Steel)');
xlabel('Strain (\epsilon)'); ylabel('Stress (MPa)');
grid on;

%% 2. 1D Finite Element Analysis (Bar)
disp('--- 2. 1D Bar Under Axial Load ---');
L_val = 1.0; n_elements = 10;
dx_val = L_val / n_elements;
A_val = 0.01; % Area
K_mat = zeros(n_elements + 1, n_elements + 1);
F_vec = zeros(n_elements + 1, 1);
F_vec(end) = 1000; % 1kN load at end

ke_mat = (E_val * A_val / dx_val) * [1, -1; -1, 1];
for i = 1:n_elements
    K_mat(i:i+1, i:i+1) = K_mat(i:i+1, i:i+1) + ke_mat;
end

% Boundary condition (fixed at x=0)
K_red = K_mat(2:end, 2:end);
F_red = F_vec(2:end);
u_vec = inv(K_red) * F_red;
u_vec = [0; u_vec];

figure;
plot(linspace(0, L_val, n_elements+1), u_vec * 1000, 'ro-', 'LineWidth', 1.5);
title('Axial Displacement (FEA)');
xlabel('Position (m)'); ylabel('Displacement (mm)');
grid on;

%% 3. Atomic Vibration Simulator
disp(' ');
disp('--- 3. Atomic Vibration Simulator ---');

function s_out = lattice_step(s_in, p)
    s_out = s_in;
    s_out.pos = s_in.pos + randn(10, 2) * 0.02;
end

function lattice_draw(ax, s)
    scatter(ax, s.pos(:, 1), s.pos(:, 2), 100, 'b', 'filled');
    title(ax, 'Atomic Vibrations in Crystal Lattice');
    axis(ax, 'equal'); xlim(ax, [-2, 2]); ylim(ax, [-2, 2]);
end

simulate('algorithm', 'step', @lattice_step, 'draw', @lattice_draw, 'state', struct('pos', randn(10, 2)*0.1));

disp('Materials Science Session Complete.');
