function p = lognormal_pdf(x, mu, sigma)
    % LOGNORMAL_PDF Log-normal distribution probability density function
    if nargin < 1, x = []; end
    if nargin < 2, mu = []; end
    if nargin < 3, sigma = []; end
    p = zeros(size(x));
    idx = x > 0;
    p(idx) = (1 ./ (x(idx) .* sigma .* sqrt(2 * pi()))) .* exp(-((log(x(idx)) - mu).^2) ./ (2 * sigma^2));
end
