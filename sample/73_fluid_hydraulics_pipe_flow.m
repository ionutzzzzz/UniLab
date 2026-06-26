% 73_fluid_hydraulics_pipe_flow.m
% UniLab Complex Hydraulics & Fluid Dynamics study
% This script models a gravity-fed water delivery pipeline: calculates the discharge velocity
% using Bernoulli's equation, and computes the friction factor, Reynolds number, and pressure drop
% across the downstream delivery pipeline using Colebrook-White and Darcy-Weisbach formulations.

clear all;
close all;
clc;

disp('🏗️ UniLab Hydraulics & Delivery Pipeline Simulation');
disp('====================================================');

% Reservoir states
P_reservoir = 250000.0; % Pressure at top reservoir surface (Pa)
P_delivery = 101325.0;  % Atmospheric discharge pressure at pipe exit (Pa)
z_reservoir = 15.0;     % Elevation of reservoir (m)
z_discharge = 2.0;      % Elevation of discharge nozzle (m)
rho_water = 1000.0;     % Water density (kg/m^3)
mu_water = 0.001;       % Water dynamic viscosity (Pa*s)

disp('Calculating downstream flow velocity using Bernoulli''s equation...');
V_exit = engineering.bernoulli_flow_rate(P_reservoir, P_delivery, z_reservoir, z_discharge, rho_water);
fprintf('  Nozzle Exit Velocity: %.4f m/s\n', V_exit);

% Pipeline parameters
pipe_D = 0.08;          % Pipe inner diameter (m)
pipe_L = 150.0;         % Pipeline length (m)
pipe_roughness = 0.000045; % Absolute roughness (m) (commercial steel)

% Volumetric flow rate Q = V * Area
pipe_area = pi * (pipe_D^2) / 4.0;
Q_flow = V_exit * pipe_area;
fprintf('  Volumetric Flow Rate: %.6f m^3/s (%.2f L/min)\n', Q_flow, Q_flow * 60000.0);

disp('\nComputing pipeline friction losses and pressure drop...');
loss_results = engineering.fluid_pipe_pressure_drop(Q_flow, pipe_D, pipe_L, pipe_roughness, rho_water, mu_water);

fprintf('  Reynolds Number (Re):    %.2e\n', loss_results.reynolds_number);
fprintf('  Darcy Friction Factor:   %.5f\n', loss_results.friction_factor);
fprintf('  Delivery Line Velocity:  %.4f m/s\n', loss_results.velocity_m_s);
fprintf('  Pipeline Pressure Drop:  %.2f kPa\n', loss_results.pressure_drop_pa / 1000.0);

% Study pressure drop over a range of flow rates
flow_rates = linspace(0.005, 0.03, 10);
p_drops = [];

for i = 1:length(flow_rates)
    res = engineering.fluid_pipe_pressure_drop(flow_rates(i), pipe_D, pipe_L, pipe_roughness, rho_water, mu_water);
    p_drops = [p_drops; res.pressure_drop_pa / 1000.0];
end

figure;
plot(flow_rates * 1000.0, p_drops, 'c-s', 'LineWidth', 1.5);
title('Pipeline Pressure Drop vs. Volumetric Flow Rate');
xlabel('Flow Rate (L/s)');
ylabel('Pressure Loss (kPa)');
grid on;

disp('Hydraulics pipeline simulation completed.');
