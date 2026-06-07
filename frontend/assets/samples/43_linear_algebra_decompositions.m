% 43_linear_algebra_decompositions.m
% UniLab Linear Algebra: Factorizations & Least Squares

clear all;
clc;

disp('🔢 UniLab Linear Algebra Factorizations');
disp('========================================');

%% 1. Orthonormalization (Gram-Schmidt)
disp('--- 1. Modified Gram-Schmidt ---');
A = [1, 1, 0; 1, 0, 1; 0, 1, 1];
[Q, R] = modified_gram_schmidt(A);

disp('Orthonormal Matrix Q:');
disp(Q);
disp('Upper Triangular Matrix R:');
disp(R);

% Verify Q*Q' = I
if is_unitary(Q)
    disp('Verification: Q is unitary.');
end

%% 2. Positive Definite Systems (Cholesky)
disp(' ');
disp('--- 2. Cholesky Decomposition ---');
% Symmetric Positive Definite Matrix
S = [4, 1, 1; 1, 2, 3; 1, 3, 6];
L = cholesky_decomposition(S);

disp('Cholesky Factor L:');
disp(L);
disp('Verification L*L'':');
disp(L * L');

%% 3. Matrix Rank and Pseudoinverse
disp(' ');
disp('--- 3. Low-Rank Approximation ---');
B = [1, 2, 3; 2, 4, 6; 3, 6, 9]; % Rank 1
rank_b = matrix_rank_approx(B);
fprintf('Detected Rank of B: %d\n', rank_b);

B_pinv = pseudoinverse_approx(B);
disp('Moore-Penrose Pseudoinverse of B:');
disp(B_pinv);

%% 4. Vector Projections
disp(' ');
disp('--- 4. Vector Subspaces ---');
u = [3; 4; 0];
v = [1; 0; 0];
p = vector_projection(u, v);
fprintf('Projection of [3, 4, 0] onto [1, 0, 0] is: [%.1f, %.1f, %.1f]\n', p(1), p(2), p(3));

disp('Linear Algebra Showcasing Complete.');