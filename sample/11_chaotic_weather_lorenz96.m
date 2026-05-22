% 11_chaotic_weather_lorenz96.m
% UniLab Atmospheric Science: Lorenz 96 Chaotic Weather Model

clear all;
close all;
clc;

disp('🌪️ UniLab Atmospheric Science Lab');
disp('==================================');

%% 1. Lorenz 96 Model (The butterfly effect in weather)
disp('--- 1. Lorenz 96 System Dynamics ---');
K_d = 40; F_f = 8.0;
y_i = F_f * ones(1, K_d);
y_i(20) = y_i(20) + 0.01;

function dr = lorenz96(t_v, r_s, F)
    K = size(r_s, 2);
    dr = zeros(1, K);
    for i = 1:K
        im2 = mod(i-3, K) + 1;
        im1 = mod(i-2, K) + 1;
        ip1 = mod(i, K) + 1;
        dr(i) = (r_s(ip1) - r_s(im2)) * r_s(im1) - r_s(i) + F;
    end
end

[Tv, Ym] = ode45_custom(@(t, y) lorenz96(t, y, F_f), [0, 30], y_i);

figure;
imagesc(Ym');
colorbar;
title('Lorenz 96: Atmospheric Wave Dynamics');
xlabel('Time'); ylabel('Spatial Variable (Index)');

%% 2. Predictability Horizon (Butterfly Effect)
disp(' ');
disp('--- 2. Predictability Horizon ---');
y_p = y_i;
y_p(20) = y_p(20) + 1e-6;
[T2, Y2] = ode45_custom(@(t, y) lorenz96(t, y, F_f), [0, 30], y_p);

d_e = sqrt(sum((Ym - Y2).^2, 2));

figure;
plot(Tv, log10(d_e + 1e-15), 'r-', 'LineWidth', 2);
title('Error Growth (Butterfly Effect)');
xlabel('Time'); ylabel('Log_{10}(RMS Error)');
grid on;

%% 3. Chaotic Attractor Visualization
disp(' ');
disp('--- 3. Interactive Lorenz Attractor ---');
simulate('lorenz', 'rho', 28.0, 'sigma', 10.0);

disp('Atmospheric Science Session Complete.');
