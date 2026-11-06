function p = pareto_pdf(x, xm, alpha)
    % PARETO_PDF Pareto distribution probability density function
    if nargin < 1, x = []; end
    if nargin < 2, xm = []; end
    if nargin < 3, alpha = []; end
    p = zeros(size(x));
    idx = x >= xm;
    p(idx) = (alpha * xm^alpha) ./ x(idx).^(alpha + 1);
end
