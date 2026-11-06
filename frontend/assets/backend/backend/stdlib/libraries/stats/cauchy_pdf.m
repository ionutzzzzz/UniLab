function p = cauchy_pdf(x, x0, gamma)
    % CAUCHY_PDF Cauchy distribution probability density function
    if nargin < 1, x = []; end
    if nargin < 2, x0 = []; end
    if nargin < 3, gamma = []; end
    p = 1 / (pi() * gamma * (1 + ((x - x0) / gamma)^2));
end
