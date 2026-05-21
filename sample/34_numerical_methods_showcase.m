% 34_numerical_methods_showcase.m
% UniLab Numerical Analysis: Root Finding & Integration Benchmark

clear all;
clc;

disp('🧮 UniLab Numerical Methods Laboratory');
disp('======================================');

%% 1. Root Finding Comparison
disp('--- 1. Root Finding: f(x) = x^2 - sin(x) - 0.5 ---');
f = @(x) x.^2 - sin(x) - 0.5;

% Brent's Method (Highly robust)
root_brent = brent_method_root(f, 0, 2, 1e-8);
% Secant Method (Fast but needs two points)
root_secant = secant_method(f, 0, 2, 1e-8);

fprintf('Root (Brent):  %.10f\n', root_brent);
fprintf('Root (Secant): %.10f\n', root_secant);

%% 2. Integration Comparison
disp(' ');
disp('--- 2. Integration: Integral of e^(-x^2) from 0 to 1 ---');
g = @(x) exp(-x.^2);

% Romberg Integration (Iterative refinement)
[I_romberg, iter] = romberg_integration(g, 0, 1, 1e-10);
% Gaussian Quadrature (High precision for polynomials/smooth funcs)
I_gauss = gauss_quadrature_2point(g, 0, 1);
% Simpson's Rule
x_simp = linspace(0, 1, 11);
y_simp = g(x_simp);
I_simpson = simpson(y_simp, x_simp);

fprintf('Integral (Romberg): %.10f (after %d steps)\n', I_romberg, iter);
fprintf('Integral (Gauss):   %.10f\n', I_gauss);
fprintf('Integral (Simpson): %.10f\n', I_simpson);

%% 3. Cubic Spline Interpolation
disp(' ');
disp('--- 3. Cubic Spline Interpolation ---');
x_pts = [0, 1, 2, 3, 4, 5];
y_pts = [0, 0.8, 0.9, 0.1, -0.8, -1.0];
xi = linspace(0, 5, 100);

yi = cubic_spline_interp(x_pts, y_pts, xi);

figure;
plot(x_pts, y_pts, 'ro', 'MarkerFaceColor', 'r'); hold on;
plot(xi, yi, 'b-', 'LineWidth', 1.5);
title('Natural Cubic Spline Interpolation');
xlabel('x'); ylabel('y');
grid on; hold off;

%% 4. Matrix Stability
disp(' ');
disp('--- 4. Matrix Condition & Stability ---');
A = [1, 2; 1.0001, 2];
c_num = matrix_condition_number(A);
fprintf('Condition Number of nearly singular A: %.2f\n', c_num);

disp('Numerical Analysis Showcase Complete.');