% 08_fractal_geometry.m
% UniLab Fractal Geometry: Mandelbrot Sets and Chaos

disp('🌀 UniLab Fractal & Chaos Studio');
disp('================================');

%% 1. Mandelbrot Set Generation
disp('--- 1. Generating Mandelbrot Set ---');
disp('Computing high-resolution fractal grid...');
M = mandelbrot(800, 800, 100);

disp('Fractal matrix generated. Opening Heatmap view...');
heatmap(M);
title('Mandelbrot Convergence Heatmap');
colormap('inferno');

%% 2. Chaos Theory: Lorenz Attractor
disp(' ');
disp('--- 2. Chaos Theory (Lorenz) ---');
disp('Launching 3D Chaotic Attractor Simulator...');
% sigma=10, rho=28, beta=8/3
simulate('lorenz', 'sigma', 10, 'rho', 28, 'time', [0, 50]);

disp(' ');
disp('Chaos Studio Complete.');
