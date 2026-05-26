% 65_aerospace_supersonic_flow.m
% UniLab Aerospace Engineering: Oblique Shock & Supersonic Airfoil Analysis
% This script simulates supersonic flow over a wedge using linearized theory.

clear all;
close all;
clc;

disp('🚀 UniLab Supersonic Aerodynamics Lab');
disp('=======================================');

%% 1. Mach Number & Flow Properties
disp('--- 1. Atmospheric Conditions ---');
M_infinity = 2.5; % Supersonic Mach number
gamma = 1.4;      % Ratio of specific heats
P_infinity = 101325; % Ambient pressure (Pa)

fprintf('Upstream Mach Number: %.1f\n', M_infinity);
fprintf('Flow Status: %s\n', 'SUPERSONIC');

%% 2. Linearized Supersonic Theory (Ackeret Theory)
disp(' ');
disp('--- 2. Linearized Pressure Coefficient ---');
% For small angles theta, Cp approx 2 * theta / sqrt(M^2 - 1)
beta = sqrt(M_infinity^2 - 1);

% Define an airfoil profile (Diamond Airfoil)
% Wedge angle = 5 degrees
theta_deg = 5.0;
theta_rad = deg2rad_custom(theta_deg);

Cp_upper = 2 * theta_rad / beta;
Cp_lower = -2 * (-theta_rad) / beta; % Symmetric

fprintf('Wedge Angle: %.1f degrees\n', theta_deg);
fprintf('Pressure Coefficient (Cp) on Upper Surface: %.4f\n', Cp_upper);

%% 3. Lift and Drag Estimation
disp('--- 3. Force Coefficients ---');
% For a symmetric diamond airfoil at zero alpha
% Lift is zero, Wave Drag is P_upper*sin(theta) + ...
% Cd_wave = 4 * theta^2 / sqrt(M^2 - 1)
Cd_wave = 4 * theta_rad^2 / beta;

fprintf('Wave Drag Coefficient (Cd): %.4f\n', Cd_wave);

%% 4. Shock Wave Visualization
disp(' ');
disp('--- 4. 2D Flow Visualization (Streamlines) ---');
[X, Y] = meshgrid(linspace(0, 2, 40), linspace(-0.5, 0.5, 40));
U = M_infinity; % Velocity scale

% Simplified flow deflection
Vx = ones(size(X)) * U;
Vy = zeros(size(X));

% Deflect flow after x=0.5 (Wedge start)
for i = 1:size(X, 1)
    for j = 1:size(X, 2)
        if X(i,j) > 0.5
            % Deflect towards centerline
            dist_to_shock = Y(i,j) - (X(i,j)-0.5)*tan(theta_rad);
            if abs(Y(i,j)) < (X(i,j)-0.5)*tan(theta_rad)
                Vy(i,j) = U * tan(theta_rad) * sign(Y(i,j));
            end
        end
    end
end

figure;
quiver(X, Y, Vx, Vy); hold on;
% Draw wedge
plot([0.5, 1.5, 0.5], [0, 0.1, 0], 'k-', 'LineWidth', 2);
title(['Supersonic Flow over Wedge (M=', num2str(M_infinity), ')']);
xlabel('x/c'); ylabel('y/c');
axis equal; grid on;

disp('Supersonic Aerodynamics Session Complete.');
