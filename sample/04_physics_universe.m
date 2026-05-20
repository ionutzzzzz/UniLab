% 04_physics_universe.m
% UniLab Physics Universe: Chaotic Dynamics and Wave Equations

disp('🌌 UniLab Physics Universe Gallery');
disp('===================================');

%% 1. Chaotic Double Pendulum
disp('--- 1. Double Pendulum (Chaos Theory) ---');
% High-sensitivity chaotic motion
simulate('double_pendulum', 'l1', 1.0, 'l2', 1.0, 'm1', 2.0, 'm2', 1.0, 'time', [0, 30]);

%% 2. Partial Differential Equations (Wave)
disp(' ');
disp('--- 2. 1D Wave Equation (PDE) ---');
disp('Visualizing vibrating string dynamics...');
simulate('wave', 'c', 2.0, 'L', 10, 'n', 80, 'time', [0, 10]);

%% 3. Optimization (Gradient Descent)
disp(' ');
disp('--- 3. Numerical Optimization Surface ---');
disp('Watching a ball find the minimum of a 3D surface...');
simulate('optimization', 'lr', 0.05, 'start_x', 2.5, 'start_y', -2.5);

%% 4. N-Body Interaction
disp(' ');
disp('--- 4. N-Body Gravity Problem ---');
disp('Simulating orbital mechanics...');
simulate('nbody', 'G', 5.0, 'time', [0, 15]);

disp(' ');
disp('Physics Universe Gallery Complete.');
