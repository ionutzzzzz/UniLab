% 41_astronomy_stellar_evolution.m
% UniLab Astronomy: Star Properties & Schwarzschild Limits

clear all;
clc;

disp('🌟 UniLab Stellar Evolution Lab');
disp('================================');

%% 1. Stellar Luminosity & Temperature
disp('--- 1. Star Luminosity Profile ---');
% Using Stefan-Boltzmann constant (W/m^2/K^4)
sigma_sb = 5.670374419e-8;

% Compare Sun with a Blue Giant (Rigel)
R_sun = 6.957e8;      % meters
T_sun = 5778;         % Kelvin
R_rigel = 79 * R_sun; % meters
T_rigel = 12100;      % Kelvin

L_sun = luminosity_star(R_sun, T_sun, sigma_sb);
L_rigel = luminosity_star(R_rigel, T_rigel, sigma_sb);

fprintf('Luminosity of the Sun:   %.2e Watts\n', L_sun);
fprintf('Luminosity of Rigel:     %.2e Watts (%.1f L_sun)\n', L_rigel, L_rigel/L_sun);

%% 2. Schwarzschild Radius (Relativistic Limits)
disp(' ');
disp('--- 2. Black Hole Event Horizons ---');
G_const = 6.67430e-11;
c_light = 299792458;

M_earth = 5.972e24;
M_sun = 1.989e30;
M_galaxy = 4e6 * M_sun; % Supermassive BH (Sgr A*)

rs_earth = schwarzschild_radius(G_const, M_earth, c_light);
rs_sun = schwarzschild_radius(G_const, M_sun, c_light);
rs_sgr_a = schwarzschild_radius(G_const, M_galaxy, c_light);

fprintf('Schwarzschild Radius (Earth): %.2f mm\n', rs_earth * 1000);
fprintf('Schwarzschild Radius (Sun):   %.2f km\n', rs_sun / 1000);
fprintf('Schwarzschild Radius (SgrA*): %.2f Million km\n', rs_sgr_a / 1e9);

%% 3. Eddington Luminosity (Stability)
disp(' ');
disp('--- 3. Eddington Stability Limit ---');
% Max mass for a star to be stable (theoretical)
M_limit = eddington_luminosity(100 * M_sun);
fprintf('Eddington Limit for 100 Solar Mass star: %.2e Watts\n', M_limit);

%% 4. Hubble expansion
disp(' ');
disp('--- 4. Cosmological Recession ---');
H0 = 70.0; % km/s/Mpc
Distances = [10, 100, 1000]; % Mpc

for d = Distances
    v = hubble_law(H0, d);
    z = redshift(v/c_light + 1, 1); % Simplified redshift
    fprintf('Galaxy at %d Mpc: v = %.2f km/s, z approx %.4f\n', d, v, z);
end

disp('Stellar Evolution Session Complete.');