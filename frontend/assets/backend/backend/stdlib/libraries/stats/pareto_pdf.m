function p = pareto_pdf(x, xm, alpha)
    % PARETO_PDF Pareto distribution probability density function
    p = zeros(size(x));
    idx = x >= xm;
    p(idx) = (alpha * xm^alpha) ./ x(idx).^(alpha + 1);
end
