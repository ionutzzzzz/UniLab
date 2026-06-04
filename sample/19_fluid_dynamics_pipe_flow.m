% 19_fluid_dynamics_pipe_flow.m
% Demonstrates internal pipe flow and aerodynamics

clear all;
clc;

disp('🚰 UniLab Fluid Dynamics');
disp('========================');

disp('--- 1. Pipe Flow Regime Analysis ---');
rho_water = 998; % kg/m^3
v_flow = 1.5; % m/s
diameter = 0.05; % 5cm pipe
mu_water = 0.001001; % dynamic viscosity at 20C

Re = reynolds_number(rho_water, v_flow, diameter, mu_water);
fprintf('Reynolds Number: %.2f ', Re);

if Re > 4000
    disp('Flow Regime: TURBULENT');
elseif Re < 2100
    disp('Flow Regime: LAMINAR');
else
    disp('Flow Regime: TRANSITIONAL');
end

disp('--- 2. Aerodynamics: Mach Number ---');
v_aircraft = 850; % m/s
c_sound_high_alt = 295; % m/s at 30,000 ft
Ma = mach_number(v_aircraft, c_sound_high_alt);

fprintf('Aircraft Speed: %.2f m/s', v_aircraft);
fprintf('Mach Number: %.2f', Ma);
if Ma > 1.0
    disp('Status: SUPERSONIC FLIGHT');
end