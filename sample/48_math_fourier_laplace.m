% 48_math_fourier_laplace.m
% UniLab Mathematics: Integral Transforms

clear all;
close all;
clc;

disp('〰️ UniLab Math: Integral Transforms');
disp('====================================');

disp('--- 1. Signal Definition ---');
t = linspace(0, 5, 200)';
% Superposition of two frequencies with exponential decay
f_t = exp(-0.5 * t) .* (sin(2*pi()*2*t) + 0.5*cos(2*pi()*5*t));

figure;
subplot(3, 1, 1);
plot(t, f_t, 'b-', 'LineWidth', 2);
title('Time Domain: e^{-0.5t}(sin(4\pi t) + 0.5cos(10\pi t))');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;

disp('--- 2. Numerical Fourier Transform ---');
f_range = linspace(0, 10, 100);
F_f = fourier_approx(t, f_t, f_range);

subplot(3, 1, 2);
plot(f_range, abs(F_f), 'r-', 'LineWidth', 2);
title('Fourier Transform Magnitude (Frequency Domain)');
xlabel('Frequency (Hz)'); ylabel('|F(f)|');
grid on;

disp('--- 3. Numerical Laplace Transform ---');
s_range = linspace(0, 2, 50);
L_s = laplace_approx(t, f_t, s_range);

subplot(3, 1, 3);
plot(s_range, abs(L_s), 'g-', 'LineWidth', 2);
title('Laplace Transform (Real s-Domain)');
xlabel('s'); ylabel('|L(s)|');
grid on;

disp('Integral Transforms calculation complete.');