% 06_numerical_analysis.m
% UniLab Numerical Analysis: Precision Root Finding, Integration, and Global Optimization

disp('🧮 UniLab Numerical Analysis Suite');
disp('===================================');

%% 1. Root Finding (Newton-Raphson)
disp('--- 1. Root Finding ---');
% Find root of f(x) = x^3 - 2x - 5
f = @(x) x^3 - 2*x - 5;
df = @(x) 3*x^2 - 2;
x0 = 2; 
% Manually implement NR for transparency
x = x0;
for i = 1:5
    x = x - f(x)/df(x);
    disp(['Iteration ', num2str(i), ': x = ', num2str(x)]);
end
disp(['Final Root: ', num2str(x)]);

%% 2. Global Optimization (Particle Swarm Heuristic)
disp(' ');
disp('--- 2. Global Optimization (PSO) ---');
% We want to find the minimum of the Ackley function (complex surface)
% Ackley function is known for many local minima
disp('Launching Particle Swarm Optimizer on Ackley Function...');
% The simulator supports a generic optimization model if we define the objective
ackley = @(x, y) -20*exp(-0.2*sqrt(0.5*(x^2 + y^2))) - exp(0.5*(cos(2*pi*x) + cos(2*pi*y))) + exp(1) + 20;
simulate(ackley, 't_range', [-5, 5], 'title', 'Ackley Surface Optimization');

%% 3. Numerical Integration
disp(' ');
disp('--- 3. Adaptive Integration ---');
% Integrate sin(x)/x from 0.01 to 10
si_func = @(x) sin(x)./x;
area = integral_custom(si_func, 0.01, 10);
disp(['Integral of sin(x)/x from 0 to 10 ≈ ', num2str(area)]);

disp(' ');
disp('Numerical Analysis Complete.');
