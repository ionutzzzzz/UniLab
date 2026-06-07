% 38_structural_mechanics_beam.m
% UniLab Structural Mechanics: Cantilever Beam & Matrix Stability

clear all;
close all;
clc;

disp('🏗️ UniLab Structural Mechanics Analysis');
disp('=======================================');

%% 1. Cantilever Beam Deflection
disp('--- 1. Beam Deflection Profile ---');
L = 5.0;      % Beam length (m)
E = 210e9;    % Modulus of elasticity for steel (Pa)
I = 1.5e-5;   % Area moment of inertia (m^4)
P = 5000;     % Point load at the end (N)

x_pos = linspace(0, L, 100);
y_defl = bernoulli_beam_deflection(P, L, E, I, x_pos);

figure;
plot(x_pos, y_defl * 1000, 'b-', 'LineWidth', 2.5);
title('Cantilever Beam Deflection Profile');
xlabel('Position along beam (m)'); ylabel('Deflection (mm)');
grid on;

fprintf('Maximum deflection at the tip (x=L): %.2f mm\n', y_defl(end) * 1000);

%% 2. Structural Matrix Condition
disp(' ');
disp('--- 2. Stiffness Matrix Sensitivity ---');
% Construct a simplified local stiffness matrix for a truss element
c = 0.5; s = 0.866; k_const = 1e7;
K_local = k_const * [c*c, c*s, -c*c, -c*s;
                     c*s, s*s, -c*s, -s*s;
                    -c*c, -c*s,  c*c,  c*s;
                    -c*s, -s*s,  c*s,  s*s];

% This matrix is singular (rank 1), condition number will be inf
r = matrix_rank_approx(K_local);
cond_num = matrix_condition_number(K_local);

fprintf('Rank of the unconstrained local stiffness matrix: %d\n', r);
fprintf('Condition number (unconstrained): %.2e\n', cond_num);

% Apply boundary conditions (constrain first two DOFs)
K_constrained = K_local(3:4, 3:4);
cond_num_fixed = matrix_condition_number(K_constrained);
fprintf('Condition number after fixing support: %.2f\n', cond_num_fixed);

%% 3. Numerical Stability (Cholesky)
disp(' ');
disp('--- 3. Stress Matrix Decomposition ---');
% A positive definite stress-related matrix
S = [4, 12, -16; 12, 37, -43; -16, -43, 98];
L_chol = cholesky_decomposition(S);

disp('Cholesky Factor L (S = L*L''):');
disp(L_chol);

if is_positive_definite(S)
    disp('Property Verified: Matrix S is Positive Definite.');
end

disp('Structural Mechanics Session Complete.');