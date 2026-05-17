disp('🚀 UniLab: Advanced Optimization & ODEs');
disp('========================================');

% 1. Numerical Integration (ODEs)
disp('--- 1. Solving Pendulum ODE ---');
% y'' + (g/L)sin(y) = 0 -> y1' = y2, y2' = -(g/L)sin(y1)
g = 9.81; len = 1.0;
pendulum_ode = @(t, y) [y(2); -(g/len)*sin(y(1))];
[t_ode, y_ode] = ode45_custom(pendulum_ode, [0 10], [pi/4 0]);

plot(t_ode, y_ode(:, 1));
title('Pendulum Motion: Angular Position');
xlabel('Time (s)'); ylabel('\theta (rad)');

% 2. Gradient-Based Optimization
disp(' ');
disp('--- 2. Function Optimization ---');
% Minimize Rosenbrock function: f(x,y) = (1-x)^2 + 100(y-x^2)^2
rosen = @(v) (1-v(1))^2 + 100*(v(2)-v(1)^2)^2;
x0 = [-1.2, 1.0];
[x_opt, f_val] = gradient_descent(rosen, x0, 0.001, 1000);
disp(['Optimized Point (Rosenbrock): ', mat2str(x_opt)]);
disp(['Minimum Value: ', num2str(f_val)]);

% 3. Peak Detection
disp(' ');
disp('--- 3. Peak Detection ---');
x_peaks = 0:0.1:10;
y_peaks = sin(x_peaks) + 0.5*sin(2.5*x_peaks);
[pks, locs] = find_peaks(y_peaks);
disp(['Peaks found at indices: ', mat2str(locs)]);

disp(' ');
disp('Optimization Tasks Complete.');
