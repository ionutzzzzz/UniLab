% 12_custom_parameters.m
% UniLab Tunable Parameters & Custom Sliders
% This script demonstrates how to add dynamic sliders to your simulations.

disp('🎛️ Tunable Parameters Demonstration');
disp('====================================');

%% 1. Interactive Sine Wave
disp('Launching a sine wave with tunable frequency and amplitude...');

% Define a function that takes time (t) and a parameters object (p).
% The parameters in 'p' will be linked to the sliders we define.
wave_func = @(t, p) p.amp * sin(p.freq * t);

% We use 'tunables' to define sliders: { 'name': [min, max, initial] }
simulate(wave_func, ...
    'tunables', struct('freq', [1, 20, 5], 'amp', [0.1, 3, 1]), ...
    't_range', [0, 10]);

disp('Try moving the "freq" and "amp" sliders in the simulation window!');

%% 2. Custom Physics (Damped Pendulum)
disp(' ');
disp('Launching a pendulum with tunable Gravity and Length...');

% We can also add tunables to built-in physics models!
simulate('pendulum', ...
    'tunables', struct('g', [1, 50, 9.81], 'length', [0.2, 5, 1.0], 'b', [0, 1, 0.25]));

disp('Adjust the physical constants live and watch the pendulum respond.');

%% 3. Machine Learning (Polynomial Overfitting)
disp(' ');
disp('Launching regression with tunable noise and degree...');

% Note: RegressionSimulator handles its own sliders, 
% but we could add more if we wanted to pass them to a custom model.
simulate('regression', 'degree', 3);

disp(' ');
disp('✅ Custom parameters allow for deep exploration of models.');
