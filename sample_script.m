% Sample UniLab MATLAB script
disp('Initializing simulation...');

% Create a matrix
A = [1, 2, 3; 4, 5, 6; 7, 8, 9];
B = eye(3) * 10;

% Matrix multiplication
C = A * B;

disp('Resulting Matrix C:');
disp(C);

% Create a plot
t = 0:0.01:1;
f = 5; % 5 Hz
signal = sin(2 * pi * f * t);

figure();
plot(t, signal, '-b', 'LineWidth', 1.5);
title('5Hz Sine Wave');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

% Save the plot
save_plot('plots/simulation_result.png');

disp('Simulation complete.');
