function r = rand_student_t_custom(nu, n)
    if nargin < 2, n = 1; end
    Z = randn(n, 1);
    V = rand_chi_square_custom(nu, n);
    r = Z .* sqrt(nu ./ V);
end