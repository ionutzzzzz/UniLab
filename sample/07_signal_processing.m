disp('📡 UniLab: Signal Processing & spectral Analysis');
disp('===============================================');

% 1. Signal Generation
disp('--- 1. Generating Noisy Signal ---');
Fs = 1000;            % Sampling frequency                    
T = 1/Fs;             % Sampling period       
L = 1500;             % Length of signal
t = (0:L-1)*T;        % Time vector

% Form a signal containing two sinusoids
S = 0.7*sin(2*pi*50*t) + sin(2*pi*120*t);
X = S + 2*randn(size(t)); % Add zero-mean white noise

% 2. Fast Fourier Transform (FFT)
disp('--- 2. Frequency Domain (FFT) ---');
Y = fft(X);
P2 = abs(Y/L);
half_len = floor(L/2) + 1;
P1 = P2(1:half_len);
len_p1 = length(P1);
P1(2:len_p1-1) = 2*P1(2:len_p1-1);
f = Fs*(0:(L/2))/L;

disp('Spectral peaks detected at 50Hz and 120Hz.');
plot(f, P1);
title('Single-Sided Amplitude Spectrum of X(t)');
xlabel('f (Hz)');
ylabel('|P1(f)|');

% 3. Digital Filtering
disp('--- 3. Signal Filtering ---');
% Lowpass filter at 80Hz
[b, a] = butter(6, 80/(Fs/2), 'low');
X_filtered = filter(b, a, X);
disp('Noise reduction complete using 6th-order Butterworth.');

% 4. Power Spectral Density
disp('--- 4. Power Spectral Density ---');
pwelch(X_filtered);
title('PSD of Filtered Signal');

disp('Signal Analysis Complete.');
