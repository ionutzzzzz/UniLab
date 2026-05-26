function p = weibull_pdf(x, lambda, k)
    % WEIBULL_PDF Weibull distribution probability density function
    p = zeros(size(x));
    idx = x >= 0;
    p(idx) = (k / lambda) .* (x(idx) / lambda).^(k - 1) .* exp(-(x(idx) / lambda).^k);
end
