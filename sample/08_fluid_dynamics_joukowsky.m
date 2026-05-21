% 08_fluid_dynamics_joukowsky.m
% UniLab Fluid Dynamics: Airfoil Flow & Joukowsky Transform

disp('🌊 UniLab Fluid Dynamics Laboratory');
disp('====================================');

%% 1. Potential Flow over a Cylinder
disp('--- 1. Potential Flow Visualization ---');
[X, Y] = meshgrid(linspace(-3, 3, 50), linspace(-3, 3, 50));
Z = X + 1j*Y;
U = 1.0; R = 1.0; % Free stream velocity and cylinder radius
% Complex potential: W = U*(z + R^2/z)
W = U * (Z + R^2 ./ Z);
psi = imag(W); % Stream function

figure;
contour(X, Y, psi, 30); hold on;
theta = 0:0.1:2*pi;
plot(R*cos(theta), R*sin(theta), 'k-', 'LineWidth', 2); % Cylinder
title('Streamlines: Potential Flow over Cylinder');
axis equal; grid on;
hold off;

%% 2. Joukowsky Transform (Airfoil Shape)
disp(' ');
disp('--- 2. Joukowsky Airfoil Transformation ---');
% Transform a circle in the zeta plane to an airfoil in the z plane
% z = zeta + 1/zeta
circle_center = -0.1 + 0.1j;
radius = 1.1;
theta = linspace(0, 2*pi, 200);
zeta = circle_center + radius * exp(1j * theta);
z = zeta + 1./zeta;

figure;
plot(real(z), imag(z), 'b-', 'LineWidth', 2);
title('Joukowsky Airfoil Geometry');
axis equal; grid on;

%% 3. Interactive Flow Simulator
disp(' ');
disp('--- 3. 2D Wave Propagation (Fluid) ---');
simulate('wave', 'c', 1.5, 'n', 100);

disp('Fluid Dynamics Laboratory Complete.');
