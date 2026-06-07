% 61_quantum_information_chsh.m
% UniLab Quantum Information: Bell States & CHSH Inequality Violation
% This script demonstrates quantum entanglement and the violation of local realism.

clear all;
close all;
clc;

disp('⚛️ UniLab Quantum Information Lab');
disp('==================================');

%% 1. Creating the Bell State |Phi+>
disp('--- 1. Bell State Preparation ---');
% |Phi+> = 1/sqrt(2) * (|00> + |11>)
zero = [1; 0];
one = [0; 1];

ket00 = kron(zero, zero);
ket11 = kron(one, one);
psi_bell = (1 / sqrt(2)) * (ket00 + ket11);

disp('Bell State |Phi+> Vector:');
disp(psi_bell');

%% 2. CHSH Inequality Setup
disp(' ');
disp('--- 2. CHSH Inequality Violation ---');
% Measuring observables A, A', B, B'
% Violation occurs when S = |<AB> - <AB'> + <A'B> + <A'B'>| > 2
% Quantum mechanics predicts S_max = 2*sqrt(2) approx 2.828

[sx, sy, sz] = pauli_matrices();
I = eye(2);

% Measurement angles
theta_a = 0;
theta_ap = pi() / 2;
theta_b = pi() / 4;
theta_bp = -pi() / 4;

% Observables
A  = cos(theta_a) * sz + sin(theta_a) * sx;
Ap = cos(theta_ap) * sz + sin(theta_ap) * sx;
B  = cos(theta_b) * sz + sin(theta_b) * sx;
Bp = cos(theta_bp) * sz + sin(theta_bp) * sx;

% Joint Observables
AB  = kron(A, B);
ABp = kron(A, Bp);
ApB = kron(Ap, B);
ApBp = kron(Ap, Bp);

% Expectation Values
e_ab  = real(expectation_value_calc(psi_bell(:), AB));
e_abp = real(expectation_value_calc(psi_bell(:), ABp));
e_apb = real(expectation_value_calc(psi_bell(:), ApB));
e_apbp = real(expectation_value_calc(psi_bell(:), ApBp));

% CHSH Statistic: S = |<AB> + <AB'> + <A'B> - <A'Bp>|
S = abs(e_ab + e_abp + e_apb - e_apbp);

fprintf('Expectation Values:\n');
fprintf('  <AB>:   %.4f\n', e_ab);
fprintf('  <AB''>:  %.4f\n', e_abp);
fprintf('  <A''B>:  %.4f\n', e_apb);
fprintf('  <A''Bp>: %.4f\n', e_apbp);
fprintf('\nCHSH Statistic S: %.4f\n', S);

if S > 2.0
    disp('RESULT: Bell Inequality VIOLATED! Local Realism is refuted.');
    disp('Theoretical Max: 2.8284');
else
    disp('RESULT: Inequality satisfied (No violation).');
end

%% 3. Visualization: Correlation Surface
disp(' ');
disp('--- 3. Correlation Sensitivity ---');
angles = linspace(0, 2 * pi(), 50);
corr_vals = zeros(size(angles));

for i = 1:length(angles)
    Bi = cos(angles(i)) * sz + sin(angles(i)) * sx;
    ABi = kron(sz, Bi); % Measure A in Z basis
    corr_vals(i) = real(expectation_value_calc(psi_bell(:), ABi));
end

figure;
plot(rad2deg_custom(angles), corr_vals, 'b-', 'LineWidth', 2);
title('Quantum Correlations: <Z \otimes B(\theta)>');
xlabel('Angle of B Measurement (degrees)'); ylabel('Correlation');
grid on;

disp('Quantum Information Session Complete.');
