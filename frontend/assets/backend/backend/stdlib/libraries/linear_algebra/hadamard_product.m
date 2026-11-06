function C = hadamard_product(A, B)
    % HADAMARD_PRODUCT Element-wise product of two matrices
    if nargin < 1, A = []; end
    if nargin < 2, B = []; end
    C = A .* B;
end
