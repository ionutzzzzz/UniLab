% 03_orbital_mechanics.m
% UniLab Orbital Mechanics: Two-Body Keplerian Dynamics & Hohmann Transfer

clear all;
close all;
clc;

disp('🛰️ UniLab Orbital Mechanics & Hohmann Transfer');
disp('===============================================');

%% 1. Two-Body Elliptical Orbit Integration (RK4)
disp('--- 1. Elliptical Orbit Propagation (RK4) ---');
mu = 398600.4418; % Earth gravitational parameter (km^3/s^2)
r_perigee = 6678.0; % 300 km Low Earth Orbit altitude (km)
e_orbit = 0.25;     % Eccentricity
a_semi = r_perigee / (1 - e_orbit);
v_perigee = sqrt(mu * (2 / r_perigee - 1 / a_semi));
T_orbit = 2 * pi * sqrt(a_semi^3 / mu);

fprintf('Semi-major axis: %.2f km | Orbital Period: %.2f min\n', a_semi, T_orbit / 60);

N_steps = 400;
dt = T_orbit / N_steps;
rx = zeros(1, N_steps + 1);
ry = zeros(1, N_steps + 1);
vx = zeros(1, N_steps + 1);
vy = zeros(1, N_steps + 1);
spec_energy = zeros(1, N_steps + 1);

rx(1) = r_perigee;
ry(1) = 0.0;
vx(1) = 0.0;
vy(1) = v_perigee;

function [ax_out, ay_out] = grav_accel(x, y, mu_val)
    r_mag = sqrt(x^2 + y^2);
    ax_out = -mu_val * x / (r_mag^3);
    ay_out = -mu_val * y / (r_mag^3);
end

for k = 1:N_steps
    x0 = rx(k); y0 = ry(k); u0 = vx(k); w0 = vy(k);
    r0 = sqrt(x0^2 + y0^2);
    spec_energy(k) = 0.5 * (u0^2 + w0^2) - mu / r0;

    [ax1, ay1] = grav_accel(x0, y0, mu);
    k1x = u0;               k1y = w0;
    k1u = ax1;              k1w = ay1;

    [ax2, ay2] = grav_accel(x0 + 0.5*dt*k1x, y0 + 0.5*dt*k1y, mu);
    k2x = u0 + 0.5*dt*k1u;  k2y = w0 + 0.5*dt*k1w;
    k2u = ax2;              k2w = ay2;

    [ax3, ay3] = grav_accel(x0 + 0.5*dt*k2x, y0 + 0.5*dt*k2y, mu);
    k3x = u0 + 0.5*dt*k2u;  k3y = w0 + 0.5*dt*k2w;
    k3u = ax3;              k3w = ay3;

    [ax4, ay4] = grav_accel(x0 + dt*k3x, y0 + dt*k3y, mu);
    k4x = u0 + dt*k3u;      k4y = w0 + dt*k3w;
    k4u = ax4;              k4w = ay4;

    rx(k+1) = x0 + (dt / 6) * (k1x + 2*k2x + 2*k3x + k4x);
    ry(k+1) = y0 + (dt / 6) * (k1y + 2*k2y + 2*k3y + k4y);
    vx(k+1) = u0 + (dt / 6) * (k1u + 2*k2u + 2*k3u + k4u);
    vy(k+1) = w0 + (dt / 6) * (k1w + 2*k2w + 2*k3w + k4w);
end
r_final = sqrt(rx(end)^2 + ry(end)^2);
spec_energy(end) = 0.5 * (vx(end)^2 + vy(end)^2) - mu / r_final;

%% 2. Hohmann Transfer LEO -> GEO Delta-V Analysis
disp('--- 2. Hohmann Transfer (LEO to GEO) ---');
r1 = 6778.0;  % 400 km LEO radius (km)
r2 = 42164.0; % Geostationary orbit radius (km)
a_trans = 0.5 * (r1 + r2);

v_circ1 = sqrt(mu / r1);
v_circ2 = sqrt(mu / r2);
v_trans_perigee = sqrt(mu * (2 / r1 - 1 / a_trans));
v_trans_apogee  = sqrt(mu * (2 / r2 - 1 / a_trans));

dv1 = v_trans_perigee - v_circ1;
dv2 = v_circ2 - v_trans_apogee;
dv_total = dv1 + dv2;
t_transfer_hr = (pi * sqrt(a_trans^3 / mu)) / 3600;

fprintf('Burn 1 (Perigee): %.3f km/s | Burn 2 (Apogee): %.3f km/s\n', dv1, dv2);
fprintf('Total Delta-V:    %.3f km/s | Transfer Time:   %.2f hours\n', dv_total, t_transfer_hr);

theta = linspace(0, 2*pi, 300);
p_trans = a_trans * (1 - ((r2 - r1) / (r2 + r1))^2);
e_trans = (r2 - r1) / (r2 + r1);
theta_half = linspace(0, pi, 150);
r_trans_curve = p_trans ./ (1 + e_trans * cos(theta_half));

figure;
hold on;
plot(r1 * cos(theta), r1 * sin(theta), 'b--', 'LineWidth', 1.5);
plot(r2 * cos(theta), r2 * sin(theta), 'g--', 'LineWidth', 1.5);
plot(r_trans_curve .* cos(theta_half), r_trans_curve .* sin(theta_half), 'r-', 'LineWidth', 2.2);
plot(rx, ry, 'm-', 'LineWidth', 1.5);
title('Orbital Trajectories: Elliptical Orbit & LEO-GEO Hohmann Transfer');
xlabel('X (km)');
ylabel('Y (km)');
legend('LEO Parking Orbit', 'GEO Target Orbit', 'Hohmann Transfer', 'Elliptical Test Orbit');
grid on;
hold off;

disp('Orbital Mechanics Suite Complete.');
