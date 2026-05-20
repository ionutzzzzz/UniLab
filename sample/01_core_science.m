% 01_core_science.m
% UniLab Core Science: Symbolic Calculus, Matrix Algebra, and Signal Processing

disp('🚀 UniLab Core Science Showcase');
disp('================================');

%% 1. Symbolic Mathematics
disp('--- 1. Symbolic Calculus ---');
syms x s t
% Complex expansion and simplification
expr = (x + 1)^4 - (x - 1)^4;
disp(['Expanded (x+1)^4 - (x-1)^4: ', char(expand(expr))]);

% Laplace Transform of a damped oscillator
f_t = exp(-0.5*t) * sin(2*t);
F_s = laplace(f_t, t, s);
disp('Laplace Transform of e^(-0.5t)sin(2t):');
disp(F_s);

%% 2. Advanced Matrix Operations
disp(' ');
disp('--- 2. Matrix Intelligence ---');
% Solve linear system Ax = B
A = [4, 1, -1; 2, 7, 1; 1, -3, 12];
B = [3; 19; 31];
x_sol = inv(A) * B;
disp('Solution to Ax = B:');
disp(x_sol);

% Eigenvalues of a structured matrix
M = magic(3);
e_vals = eig(M);
disp('Eigenvalues of magic(3):');
disp(e_vals);

%% 3. Signal Processing & Spectral Analysis
disp(' ');
disp('--- 3. Frequency Domain Analysis ---');
Fs = 1000; T = 1/Fs; L = 1000; t = (0:L-1)*T;
% Signal with multiple frequencies and noise
S = 0.5*sin(2*pi*50*t) + 2*sin(2*pi*120*t);
X = S + 0.5*randn(size(t));

% Apply 6th-order Butterworth Filter
[b, a] = butter(6, 100/(Fs/2), 'low');
X_clean = filter(b, a, X);

% Compute FFT
Y = fft(X_clean);
P2 = abs(Y/L); P1 = P2(1:L/2+1);
f = Fs*(0:(L/2))/L;

disp('Spectral analysis complete. Opening plot...');
plot(f, P1, 'Color', 'r', 'LineWidth', 1.5);
title('Filtered Signal Spectrum');
xlabel('Frequency (Hz)'); ylabel('|P1(f)|');
grid('on');

disp(' ');
disp('Core Science Showcase Complete.');
