% 14_gui_logreg_simulation.m
% Test the interactive GUI for Logistic Regression

disp('Starting Logistic Regression Simulator...');

% Create simple dataset (linearly separable)
X = [0 0; 0 1; 1 0; 1 1; 2 2; 2 3; 3 2; 3 3];
y = [0; 0; 0; 0; 1; 1; 1; 1];

% Create Logistic Regression model
model = ml.LogisticRegression('lr', 0.1, 'epochs', 500);

% Launch the interactive simulation GUI
simulate(model, 'X', X, 'y', y, 'epochs', 500, 'lr', 0.1);

disp('Simulation closed.');