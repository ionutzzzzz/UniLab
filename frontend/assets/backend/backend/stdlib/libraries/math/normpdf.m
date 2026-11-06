function p = normpdf(x, mu, sigma)
    % NORMPDF Normal probability density function
    if nargin < 1, x = []; end
    if nargin < 2, mu = 0; end
    if nargin < 3, sigma = 1; end
    
    p = (1 / (sigma * sqrt(2 * pi()))) * exp(-0.5 * ((x - mu) / sigma)^2);
end
