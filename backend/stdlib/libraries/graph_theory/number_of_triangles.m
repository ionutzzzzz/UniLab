function t = number_of_triangles(A)
    if nargin < 1, A = []; end
    t = matrix_trace(A^3) / 6;
end