function p = normal_pdf(x, mu, sigma)
    if nargin < 1, x = []; end
    if nargin < 2, mu = []; end
    if nargin < 3, sigma = []; end
    p = (1 / (sigma * sqrt(2 * pi()))) * exp(-0.5 * ((x - mu) / sigma)^2);
end
