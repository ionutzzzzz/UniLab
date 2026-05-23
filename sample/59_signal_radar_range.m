% 59_signal_radar_range.m
% UniLab Signal Processing: Pulse Compression & Radar Range Estimation

clear all;
close all;
clc;

disp('📡 UniLab Radar Signal Processing');
disp('==================================');

%% 1. Transmit Signal: LFM Chirp
disp('--- 1. Generating Linear Frequency Modulated (LFM) Chirp ---');
fs = 1e6;       % 1 MHz sampling
T_pulse = 1e-4; % 1ms pulse
B_width = 1e5;  % 100 kHz bandwidth
t = 0:1/fs:T_pulse;

% Chirp: sin(2*pi*(f0*t + 0.5*k*t^2))
k = B_width / T_pulse;
tx_pulse = sin(pi * k * t.^2);

figure;
subplot(3, 1, 1);
plot(t * 1e6, tx_pulse);
title('Transmitted Chirp Pulse (100 \mu s)');
xlabel('Time (\mu s)'); ylabel('Amplitude');

%% 2. Echo Simulation (Target Detection)
disp('--- 2. Simulating Echo from Target ---');
% Target at distance R
R_target = 15000; % 15 km
c_light = 3e8;
delay_s = 2 * R_target / c_light;
delay_samples = round(delay_s * fs);

% Create a long received signal with the echo
rx_len = 1000; % observation window
rx_signal = zeros(1, rx_len);
idx_start = 500; % Assume we start listening and target is at some delay
rx_signal(idx_start : idx_start + length(tx_pulse) - 1) = 0.5 * tx_pulse;

% Add noise
noise = 0.3 * randn(size(rx_signal));
rx_noisy = rx_signal + noise;

subplot(3, 1, 2);
plot(rx_noisy);
title('Noisy Received Signal (Echo Hidden in Noise)');
xlabel('Sample Index'); ylabel('Amplitude');

%% 3. Matched Filtering (Pulse Compression)
disp('--- 3. Matched Filter (Cross-Correlation) ---');
% Using xcorr for signal detection
[corr_res, lags] = xcorr(rx_noisy, tx_pulse);

% Keep only positive lags and take absolute
[~, center_idx] = max(lags == 0);
corr_mag = abs(corr_res(lags >= 0));

subplot(3, 1, 3);
plot(corr_mag, 'r-', 'LineWidth', 1.5);
title('Matched Filter Output (Compressed Pulse)');
xlabel('Delay (Samples)'); ylabel('Correlation Magnitude');

%% 4. Range Estimation
disp('--- 4. Target Range Calculation ---');
[pks, locs] = find_peaks(corr_mag, max(corr_mag)*0.7);

if ~isempty(locs)
    est_delay_samples = locs(1);
    est_delay_s = est_delay_samples / fs;
    % Note: This is an internal delay relative to start of window
    % In a real system, we'd know the exact t0.
    fprintf('Peak detected at lag: %d samples\n', est_delay_samples);
    
    % Theoretical range from peak
    est_range = (est_delay_s * c_light) / 2;
    disp(['Estimated Target Distance: ', num2str(est_range), ' meters']);
else
    disp('Target not detected.');
end

disp('Radar Processing Simulation Complete.');
