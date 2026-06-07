% 28_linear_algebra_spaces.m
% Demonstrates advanced matrix operations and vector spaces

clear all;
clc;

disp('🧮 UniLab Linear Algebra');
disp('=========================');

disp('--- 1. Vector Norms ---');
% Analyze a state vector in 3D space
state_v = [3.5, -2.1, 6.8];

n1 = vector_norm_1(state_v);
n2 = vector_norm_2(state_v);
ninf = vector_norm_inf(state_v);

fprintf('Vector: [%.1f, %.1f, %.1f]
', state_v(1), state_v(2), state_v(3));
fprintf('Manhattan (L1) Norm: %.2f
', n1);
fprintf('Euclidean (L2) Norm: %.2f
', n2);
fprintf('Maximum (L-inf) Norm: %.2f
', ninf);

disp('--- 2. Matrix Trace and Orthogonality ---');
% Create a 3D Rotation matrix around the Z axis
theta = pi/3;
R = rot_matrix_3d(theta, 'z');

disp('Rotation Matrix R_z(pi/3):');
disp(R);

tr = matrix_trace(R);
fprintf('Trace of Rotation Matrix: %.4f
', tr);

if is_orthogonal(R)
    disp('Property Check: The rotation matrix is VERIFIED as Orthogonal (R^T * R = I).');
else
    disp('Property Check: Matrix is NOT Orthogonal.');
end

% Create a symmetric matrix
S = [2, 1, 0; 1, 3, -1; 0, -1, 4];
if is_symmetric(S)
    disp('Property Check: The matrix S is VERIFIED as Symmetric.');
end
