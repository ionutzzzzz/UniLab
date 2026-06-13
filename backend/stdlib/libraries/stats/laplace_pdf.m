function p = laplace_pdf(x, mu, b)
    % LAPLACE_PDF Laplace distribution probability density function
    if nargin < 1, x = []; end
    if nargin < 2, mu = []; end
    if nargin < 3, b = []; end
    p = (1 / (2 * b)) * exp(-abs(x - mu) / b);
end
