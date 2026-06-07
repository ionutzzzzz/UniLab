% 22_astronomy_cosmology.m
% Demonstrates extreme astrophysics, relativity, and cosmological expansion

clear all;
clc;

disp('🌌 UniLab Astronomy & Cosmology');
disp('================================');

disp('--- 1. Cosmology: The Expanding Universe ---');
H0 = 70.0; % Hubble constant in km/s/Mpc
Distance_Mpc = 400; % Distance to the Coma Cluster
v_recession = hubble_law(H0, Distance_Mpc);

fprintf('Distance to target galaxy cluster: %.1f Mpc
', Distance_Mpc);
fprintf('Recessional Velocity (Hubble Flow): %.2f km/s
', v_recession);

disp('--- 2. General Relativity: Schwarzschild Radius ---');
G = 6.674e-11; c = 3e8;
M_earth = 5.972e24; % kg
M_sun = 1.989e30; % kg

rs_earth = schwarzschild_radius(G, M_earth, c);
rs_sun = schwarzschild_radius(G, M_sun, c);

fprintf('If the Earth collapsed into a black hole, its radius would be: %.4f mm
', rs_earth * 1000);
fprintf('If the Sun collapsed into a black hole, its radius would be: %.4f km
', rs_sun / 1000);

disp('--- 3. Stellar Astrophysics ---');
R_star = 6.96e8 * 10; % A star 10x the radius of the sun
T_star = 25000; % Very hot blue giant
sigma_sb = 5.67e-8;

L_star = luminosity_star(R_star, T_star, sigma_sb);
fprintf('Luminosity of Blue Giant: %.2e Watts
', L_star);
