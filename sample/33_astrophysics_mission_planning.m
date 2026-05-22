% 33_astrophysics_mission_planning.m
% UniLab Astrophysics: Orbital Transfer & Mission Planning

clear all;
close all;
clc;

disp('🌌 UniLab Astrophysics Mission Planner');
disp('========================================');

%% 1. Earth to Mars Hohmann Transfer
disp('--- 1. Hohmann Transfer: Earth to Mars ---');
% Gravitational parameter for the Sun (m^3/s^2)
mu_sun = 1.32712440018e20; 

% Average orbital radii (meters)
r_earth = 1.496e11;
r_mars = 2.279e11;

[dv1, dv2, total_dv] = hohmann_transfer(mu_sun, r_earth, r_mars);

fprintf('Delta-v for Earth Departure (v1): %.2f m/s\n', dv1);
fprintf('Delta-v for Mars Arrival (v2):   %.2f m/s\n', dv2);
fprintf('Total Mission Delta-v:           %.2f m/s\n', total_dv);

%% 2. Orbital Period and Transfer Time
disp(' ');
disp('--- 2. Transfer Orbit Characteristics ---');
a_transfer = (r_earth + r_mars) / 2;
T_transfer = orbital_period_calc(mu_sun, a_transfer);

% Time of flight is half the period
tof_days = (T_transfer / 2) / (24 * 3600);
fprintf('Transfer Semi-major Axis: %.2e meters\n', a_transfer);
fprintf('One-way Travel Time:      %.2f days\n', tof_days);

%% 3. Vis-Viva: Velocity Profile
disp(' ');
disp('--- 3. Velocity Profile Visualization ---');
r_range = linspace(r_earth, r_mars, 100);
v_profile = zeros(size(r_range));

for i = 1:length(r_range)
    v_profile(i) = vis_viva_equation(mu_sun, r_range(i), a_transfer);
end

figure;
plot(r_range / 1e9, v_profile / 1000, 'b-', 'LineWidth', 2);
title('Velocity Profile along Hohmann Transfer Orbit');
xlabel('Distance from Sun (Million km)'); ylabel('Orbital Speed (km/s)');
grid on;

%% 4. Interactive Gravity Well
disp(' ');
disp('--- 4. Interactive Gravitational Deflection ---');
% mass of Sun as lens
M_sun = 1.989e30;
b_param = 6.96e8 * 10; % 10 Solar Radii
alpha = gravitational_lensing_angle(M_sun, b_param);
fprintf('Light deflection at 10 solar radii: %.4e arcsec\n', rad2deg_custom(alpha) * 3600);

simulate('nbody', 'G', 1.0, 'time', [0, 10]);

disp('Mission Planning Session Complete.');