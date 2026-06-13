function p = f_distribution_pdf(x, d1, d2)
    % F_DISTRIBUTION_PDF F-distribution probability density function (approximation)
    % This uses the relationship with the Beta function
    if nargin < 1, x = []; end
    if nargin < 2, d1 = []; end
    if nargin < 3, d2 = []; end
    p = zeros(size(x));
    idx = x > 0;
    num = sqrt(((d1 .* x(idx)).^d1 .* d2.^d2) ./ (d1 .* x(idx) + d2).^(d1 + d2));
    den = x(idx) .* beta_custom(d1/2, d2/2);
    p(idx) = num ./ den;
end

function b = beta_custom(z, w)
    if nargin < 1, z = []; end
    if nargin < 2, w = []; end
    b = (gamma_stirling(z) * gamma_stirling(w)) / gamma_stirling(z + w);
end
