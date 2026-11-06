function p = weibull_pdf(x, lambda, k)
    % WEIBULL_PDF Weibull distribution probability density function
    if nargin < 1, x = []; end
    if nargin < 2, lambda = []; end
    if nargin < 3, k = []; end
    p = zeros(size(x));
    idx = x >= 0;
    p(idx) = (k / lambda) .* (x(idx) / lambda).^(k - 1) .* exp(-(x(idx) / lambda).^k);
end
