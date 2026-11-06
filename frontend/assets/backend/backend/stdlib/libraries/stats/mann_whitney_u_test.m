function [U, p_val] = mann_whitney_u_test(x1, x2)
    % MANN_WHITNEY_U_TEST Non-parametric test for two independent samples
    if nargin < 1, x1 = []; end
    if nargin < 2, x2 = []; end
    n1 = length(x1);
    n2 = length(x2);
    combined = [x1(:); x2(:)];
    [~, idx] = sort(combined);
    ranks = zeros(size(combined));
    ranks(idx) = 1:length(combined);
    
    R1 = sum(ranks(1:n1));
    U1 = R1 - n1 * (n1 + 1) / 2;
    U2 = n1 * n2 - U1;
    U = min(U1, U2);
    
    % Normal approximation for large samples
    mu_u = n1 * n2 / 2;
    sigma_u = sqrt(n1 * n2 * (n1 + n2 + 1) / 12);
    z = (U - mu_u) / sigma_u;
    p_val = 2 * (1 - normcdf(abs(z)));
end
