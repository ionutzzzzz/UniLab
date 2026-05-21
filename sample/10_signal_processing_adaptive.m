% 10_signal_processing_adaptive.m
% UniLab Signal Processing: Adaptive Filters & Spectral Analysis

disp('📡 UniLab Signal Processing Studio');
disp('===================================');

%% 1. LMS Adaptive Noise Cancellation
disp('--- 1. LMS Adaptive Filter ---');
N_s = 1000;
t_v = (0:N_s-1)';
s_c = sin(2*pi*0.02*t_v); 
n_n = 0.5 * randn(N_s, 1); 
x_n = s_c + n_n; 

L_f = 32; 
w_w = zeros(L_f, 1);
mu_s = 0.01; 
y_o = zeros(N_s, 1);
e_e = zeros(N_s, 1);

for i = L_f:N_s
    x_sub = x_n(i:-1:i-L_f+1);
    % explicitly flatten vectors for dot product
    xv = x_sub(:);
    y_o(i) = w_w' * xv; 
    e_e(i) = s_c(i) - y_o(i); 
    w_w = w_w + 2 * mu_s * e_e(i) * xv;
end

figure;
subplot(2, 1, 1);
plot(t_v, x_n, 'g', t_v, s_c, 'r', 'LineWidth', 1.2);
title('Noisy vs Clean Signal'); legend('Noisy', 'Original');
subplot(2, 1, 2);
plot(t_v, y_o, 'b', 'LineWidth', 1.2);
title('Adaptive Filter Output (Recovered)');
grid on;

%% 2. Spectral Analysis (Spectrogram)
disp(' ');
disp('--- 2. Time-Frequency Analysis ---');
Fs_v = 1000.0;
t_s = 0:1/Fs_v:2;
f_i = 50 + 100*t_s; 
sig_c = sin(2*pi*f_i.*t_s);

figure;
specgram(sig_c, Fs_v);
title('Chirp Signal Spectrogram');

%% 3. Interactive Signal Simulator
disp(' ');
disp('--- 3. Real-time Filter Tuning ---');

function sn = filt_step(sc, p)
    sn = sc;
    dt = 1.0/p.Fs;
    t_n = size(sc.h, 1) * dt;
    val = sin(2.0*pi*sc.f*t_n) + 0.5*randn();
    sn.h = [sc.h; val];
    if size(sn.h, 1) > 200, sn.h = sn.h(end-199:end); end
    sn.f = sc.f + 0.1 * randn();
end

function filt_draw(ax, s)
    plot(ax, s.h, 'b-');
    title(ax, ['Signal (f \approx ', num2str(s.f), ' Hz)']);
    grid(ax, 'on');
end

st_sig = struct('f', 10.0, 'h', []);
simulate('algorithm', 'step', @filt_step, 'draw', @filt_draw, 'state', st_sig, 'Fs', 1000);

disp('Signal Processing Studio Complete.');
