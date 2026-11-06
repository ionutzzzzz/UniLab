function p = exponential_pdf(x, lambda)
    if nargin < 1, x = []; end
    if nargin < 2, lambda = []; end
    p = lambda * exp(-lambda * x);
    p(x < 0) = 0;
end
