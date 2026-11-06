% 72_heat_conduction_finite_difference.m
% UniLab Complex Heat Conduction & Thermal Stress analysis
% This script solves the 1D steady-state heat conduction equation across a rod
% using the finite difference method, computes the temperature distribution, and
% calculates the resulting elastic thermal strain energy density under constrained expansion.

clear all;
close all;
clc;

disp('🏗️ UniLab Rod Heat Conduction & Thermal Strain Energy analysis');
disp('================================================================');

% Rod parameters
L = 2.0;            % Length (meters)
k_cond = 45.0;       % Thermal conductivity (W/mK)
T_boundaries = [150.0, 30.0]; % temperatures at boundaries (C)
Q_source = 2500.0;   % Localized heat generation rate (W/m^3)
n_points = 80;

disp('Solving 1D steady-state heat equation (Finite Difference)...');
[x, T] = engineering.finite_difference_1d(L, k_cond, T_boundaries, Q_source, n_points);

% Compute average temperature and maximum temperature
T_avg = mean(T);
[T_max, max_idx] = max(T);
fprintf('  Maximum Temperature: %.2f C at position x = %.4f m\n', T_max, x(max_idx));
fprintf('  Average Temperature: %.2f C\n', T_avg);

% Coupled mechanical expansion stress calculation:
% If the rod is locked at both ends, the average temperature change causes thermal stress
alpha_exp = 1.2e-5; % Coefficient of thermal expansion (1/K)
E_modulus = 200e9;  % Young's Modulus (Pa)
delta_T = T_avg - 20.0; % temperature change from reference (20 C)

strain = alpha_exp * delta_T;
stress = E_modulus * strain;
energy_density = engineering.stress_strain_strain_energy(stress, strain);

fprintf('\nThermal Stress Analysis (Locked Rod Ends):\n');
fprintf('  Thermal Strain (epsilon):       %.6f\n', strain);
fprintf('  Thermal compressive Stress (Pa): %.2f MPa\n', stress / 1e6);
fprintf('  Stored Strain Energy Density:    %.2f J/m^3\n', energy_density);

% Plot temperature distribution
figure;
plot(x, T, 'y-', 'LineWidth', 1.5);
title('1D Steady-State Temperature Distribution across Rod');
xlabel('Position along Rod (m)');
ylabel('Temperature (C)');
grid on;

disp('Thermal conduction analysis completed.');
