function p = gamma_distribution_pdf(x, a, b)
    % GAMMA_DISTRIBUTION_PDF Gamma distribution PDF (shape a, scale b)
    if nargin < 1, x = []; end
    if nargin < 2, a = []; end
    if nargin < 3, b = []; end
    p = zeros(size(x));
    idx = x > 0;
    p(idx) = (1 / (b^a * gamma_stirling(a))) * x(idx).^(a - 1) .* exp(-x(idx)/b);
end
