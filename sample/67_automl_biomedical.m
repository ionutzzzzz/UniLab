% 67_automl_biomedical.m
% UniLab Advanced Showcase: AI (AutoML, Clustering, RNNs), Engineering, and Biomedical Systems

clear all;
close all;
clc;

disp('🔬 UniLab Advanced Toolbox Demonstration');
disp('========================================');

%% --- 1. AI: AutoML Auto-Trainer, PCA, DBSCAN, RNNs, Robust Scaler ---
disp('🤖 1. AutoML and Advanced Machine Learning');
disp('-------------------------------------------------');
% Create a synthetic dataset
X = [
    1.2, 0.9;
    1.5, 1.6;
    1.1, 1.2;
    2.0, 1.8;
    0.5, 0.4;
    0.2, 0.6;
    0.8, 0.5;
    0.3, 0.2;
    2.1, 2.3;
    2.5, 2.0;
    0.1, 0.2;
    0.4, 0.5;
    1.8, 1.9;
    0.9, 0.8;
    0.6, 0.7
];
y = [1; 1; 1; 1; 0; 0; 0; 0; 1; 1; 0; 0; 1; 1; 0];

disp('Running AutoML to find the best classification model...');
best_clf = ml.fitAutoML(X, y, 'classification', true);

% 1.1 PCA Dimensionality Reduction
disp('Applying Principal Component Analysis (PCA)...');
pca_obj = ml.PrincipalComponentAnalysis(1);
X_pca = pca_obj.fit_transform(X);
disp('First 3 PCA-projected samples:');
disp(X_pca(1:3));

% 1.2 DBSCAN Clustering
disp('Running DBSCAN Clustering...');
dbscan_obj = ml.DBSCAN(0.4, 2);
dbscan_labels = dbscan_obj.fit_predict(X);
disp('DBSCAN cluster labels for dataset:');
disp(dbscan_labels);

% 1.3 Recurrent Neural Network Cell Simulation
disp('Simulating Recurrent Neural Network (RNN) forward cell...');
rnn = ml.RNNCell(2, 4);
input_val = [0.8, -0.5];
h_state = rnn.forward(input_val);
disp('RNN Hidden State output:');
disp(h_state);

% 1.4 K-Means Elbow Curve
disp('Computing K-Means Elbow distortions (k=1..5)...');
distortions = ml.kmeans_elbow_score(X, 5);
disp('Distortions:');
disp(distortions);

% 1.5 Robust Scaler centering & scaling
disp('Applying Robust Scaler to X...');
scaler = ml.RobustScaler();
X_scaled = scaler.fit_transform(X);
disp('First 3 scaled samples:');
disp(X_scaled(1:3, :));
fprintf('\n');


%% --- 2. Biomedical Simulation: Lotka-Volterra, Pharmacokinetics, DNA, Cardiac & Stroke ---
disp('🧬 2. Biomedical & Ecological Systems');
disp('---------------------------------------------------------');

% 2.1 Hodgkin-Huxley Neuron Model
disp('Simulating neuron action potential (Hodgkin-Huxley)...');
[t_hh, V_hh, m, h, n] = biomedical.hodgkin_huxley(15.0, 40.0);

% 2.2 Cardiac Action Potential (FitzHugh-Nagumo Model)
disp('Simulating cardiac action potential (FitzHugh-Nagumo)...');
[t_cardiac, v_cardiac, w_cardiac] = biomedical.cardiac_action_potential(80.0);

% 2.3 Lotka-Volterra Predator-Prey Ecology Model
disp('Simulating Lotka-Volterra predator-prey dynamics...');
[t_lv, prey, predator] = biomedical.lotka_volterra(1.1, 0.4, 0.1, 0.4, 12.0, 4.0, 30.0);

% 2.4 Pharmacokinetics (Two-Compartment Model)
disp('Simulating two-compartment PK drug concentrations (IV Bolus)...');
[t_pk, c_central, c_peripheral] = biomedical.pharmacokinetics_2comp(120.0, 0.05, 0.02, 0.04, 10.0, 20.0, 48.0);

% 2.5 Cardiac Stroke Volume and Ejection Fraction
disp('Calculating stroke volume & ejection fraction...');
stroke_stats = biomedical.cardiac_stroke_volume(130.0, 45.0);
fprintf('  Stroke Volume:     %.1f mL\n', stroke_stats.stroke_volume_ml);
fprintf('  Ejection Fraction: %.1f %%\n', stroke_stats.ejection_fraction_pct);

% 2.6 Oral Pharmacokinetics (One-Compartment Model)
disp('Simulating one-compartment PK drug concentration (Oral)...');
[t_pk_oral, c_oral] = biomedical.pharmacokinetics_1comp(100.0, 0.8, 0.1, 15.0, 24.0);

% 2.7 DNA GC Content
dna_seq = 'ATGCGATACGTTCGCAT';
gc_ratio = biomedical.dna_gc_content(dna_seq);
fprintf('  GC Content of %s: %.1f %%\n', dna_seq, gc_ratio);

% Plot Action Potentials (Neural & Cardiac)
figure;
plot(t_hh, V_hh, 'y-', 'LineWidth', 1.5);
title('Neural Action Potential (Hodgkin-Huxley)');
xlabel('Time (ms)');
ylabel('Membrane Potential (mV)');
grid on;

% Plot Lotka-Volterra
figure;
plot(t_lv, prey, 'c-', t_lv, predator, 'r-', 'LineWidth', 1.5);
title('Predator-Prey Population Dynamics');
xlabel('Time (months)');
ylabel('Population (thousands)');
grid on;

% Plot Oral PK Concentration
figure;
plot(t_pk_oral, c_oral, 'w-', 'LineWidth', 1.5);
title('One-Compartment PK Oral Drug Concentration');
xlabel('Time (hours)');
ylabel('Drug Concentration (mg/L)');
grid on;
fprintf('\n');


%% --- 3. Engineering: PID Tuning, RLC Circuits, Bode, Aerodynamics, Fourier & Projectile ---
disp('🏗️ 3. Engineering Systems');
disp('-------------------------------------------------------');

% 3.1 Deflection of Cantilever Beam
disp('Calculating cantilever beam deflection...');
[x_beam, deflection, moment] = engineering.beam_stress(5.0, 1200.0, 200e9, 1e-5, 50);

% 3.2 Series RLC Circuit Transient Response
disp('Simulating transient response of series RLC circuit...');
[t_rlc, v_cap, i_curr] = engineering.rlc_transient(8.0, 0.15, 2e-4, 12.0, 0.1);

% 3.3 Control Systems Bode Frequency Response
disp('Computing Bode frequency response for 2nd order system...');
num = [100.0];
den = [1.0, 10.0, 100.0];
[w_bode, mag_db, phase_deg] = engineering.control_bode_plot(num, den);

% 3.4 2D Projectile Motion Simulation
disp('Simulating 2D projectile trajectory (v0=25m/s, angle=45)...');
[t_proj, x_proj, y_proj, flight_time, max_height, total_range] = engineering.projectile_motion(25.0, 45.0, 1.5, 9.81);
fprintf('  Flight Time: %.2f s\n', flight_time);
fprintf('  Max Height:  %.2f m\n', max_height);
fprintf('  Total Range: %.2f m\n', total_range);

% Plot RLC circuit transients
figure;
plot(t_rlc, v_cap, 'c-', t_rlc, i_curr, 'r-', 'LineWidth', 1.5);
title('Series RLC Circuit Step Response');
xlabel('Time (s)');
ylabel('Voltage (V) / Current (A)');
grid on;

% Plot Projectile Trajectory
figure;
plot(x_proj, y_proj, 'w-', 'LineWidth', 1.5);
title('2D Projectile Trajectory');
xlabel('Horizontal Distance (m)');
ylabel('Vertical Height (m)');
grid on;

disp('Demo script execution finished.');
