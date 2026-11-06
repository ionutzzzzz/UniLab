function p = beta_distribution_pdf(x, a, b)
    % BETA_DISTRIBUTION_PDF Beta distribution PDF
    if nargin < 1, x = []; end
    if nargin < 2, a = []; end
    if nargin < 3, b = []; end
    p = zeros(size(x));
    idx = x > 0 & x < 1;
    B = beta_function(a, b);
    p(idx) = (x(idx).^(a - 1) .* (1 - x(idx)).^(b - 1)) / B;
end
