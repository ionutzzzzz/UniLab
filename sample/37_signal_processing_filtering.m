% 37_signal_processing_filtering.m
% UniLab Signal Processing: FIR Filter Design & Smoothing

clear all;
clc;

disp('📡 UniLab Filter Design Studio');
disp('==============================');

%% 1. Generate Noisy Signal
disp('--- 1. Signal Preparation ---');
fs = 1000; % 1 kHz sampling
t = (0:1/fs:1)';
signal_pure = sin(2*pi*5*t) + 0.5*sin(2*pi*50*t); % 5Hz and 50Hz
noise = 0.3 * randn(size(t));
signal_noisy = signal_pure + noise;

%% 2. FIR Filter Design
disp('--- 2. FIR Lowpass Design (Hamming Window) ---');
order = 50;
fc = 15; % 15Hz cutoff
h_fir = lowpass_filter_fir(order, fc, fs);

% Apply filter
signal_fir = filter(h_fir, 1, signal_noisy);

%% 3. Exponential Moving Average (EMA)
disp('--- 3. Recursive Smoothing (EMA) ---');
alpha = 0.1;
signal_ema = exponential_moving_average(signal_noisy, alpha);

%% 4. Spectral Analysis
disp('--- 4. Frequency Domain Visualization ---');
mag_noisy = magnitude_spectrum(signal_noisy);
mag_fir = magnitude_spectrum(signal_fir);
f_vec = (0:length(t)-1) * (fs / length(t));

figure;
subplot(2, 1, 1);
plot(t, signal_noisy, 'g', 'LineWidth', 0.5); hold on;
plot(t, signal_fir, 'b', 'LineWidth', 2);
plot(t, signal_ema, 'r', 'LineWidth', 1.5);
title('Time Domain: FIR Lowpass vs EMA Denoising');
legend('Noisy', 'FIR (15Hz)', 'EMA (\alpha=0.1)');
xlim([0, 0.5]); grid on;

subplot(2, 1, 2);
plot(f_vec, mag_noisy, 'g'); hold on;
plot(f_vec, mag_fir, 'b', 'LineWidth', 1.5);
title('Frequency Domain: Magnitude Spectrum');
legend('Noisy', 'Filtered (FIR)');
xlim([0, 100]); grid on;

%% 5. Interactive Pulse Generation
disp(' ');
disp('--- 5. Pulse Modulation Theory ---');
t_pulse = linspace(-5, 5, 200);
y_pulse = sinc_custom(t_pulse) .* hamming_window(200);

figure;
plot(t_pulse, y_pulse, 'm-', 'LineWidth', 2);
title('Windowed Sinc Pulse (Basis for Filter Design)');
grid on;

disp('Signal Processing Session Complete.');
