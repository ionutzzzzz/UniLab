function C = kronecker_product(A, B)
    % KRONECKER_PRODUCT Kronecker product of two matrices
    if nargin < 1, A = []; end
    if nargin < 2, B = []; end
    [ma, na] = size(A);
    [mb, nb] = size(B);
    C = zeros(ma*mb, na*nb);
    for i = 1:ma
        for j = 1:na
            C((i-1)*mb+1:i*mb, (j-1)*nb+1:j*nb) = A(i,j) * B;
        end
    end
end
