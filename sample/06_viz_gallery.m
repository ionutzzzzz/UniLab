disp('🎨 UniLab: High-Impact Visualization Gallery');
disp('=============================================');

% 1. Scatter Plot with Transparency
disp('--- 1. Multi-Dimensional Scatter ---');
x = randn(100, 1);
y = randn(100, 1);
scatter_plot(x, y, 'Gaussian Distribution Noise');

% 2. 3D-Like Heatmap
disp(' ');
disp('--- 2. Heatmap Matrix ---');
M = eye(10) + diag(ones(9,1)*0.5, 1) + diag(ones(9,1)*0.5, -1);
heatmap(M);
title('Symmetric Banded Matrix Heatmap');

% 3. Discrete Signal Stem Plot
disp(' ');
disp('--- 3. Signal Analysis ---');
t = 0:0.2:10;
y_signal = exp(-0.2*t) .* sin(2*pi*t/4);
stem_plot(y_signal);
title('Damped Harmonic Oscillator (Discrete)');

% 4. Terminal Graphics (Retro Mode)
disp(' ');
disp('--- 4. Terminal ASCII Plotting ---');
y_term = sin(0:0.5:10);
terminal_plot(y_term);

disp(' ');
disp('Gallery Showcase Complete.');
