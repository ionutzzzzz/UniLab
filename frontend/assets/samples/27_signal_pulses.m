% 27_signal_pulses.m
% Demonstrates foundational signals used in DSP and systems theory

clear all;
close all;
clc;

disp('📡 UniLab Signal Pulses');
disp('=======================');

t = linspace(-5, 5, 500);

% Generate basis signals
y_sinc = sinc_custom(t);
y_rect = rect_custom(t / 2.0); % Rectangular pulse of width 2
y_step = unit_step_custom(t - 1.0); % Step function delayed by 1s

% Dirac delta is mostly theoretical, but we can evaluate it directly
y_dirac = dirac_delta(t);

figure;
subplot(3, 1, 1);
plot(t, y_sinc, 'b-', 'LineWidth', 2);
title('Normalized Sinc Function: sin(\pi x) / (\pi x)'); grid on;

subplot(3, 1, 2);
plot(t, y_rect, 'r-', 'LineWidth', 2);
title('Rectangular Pulse (Width = 2)'); grid on;

subplot(3, 1, 3);
plot(t, y_step, 'g-', 'LineWidth', 2);
title('Delayed Unit Step Function u(t-1)'); grid on;

disp('Signal visualizations generated successfully.');
