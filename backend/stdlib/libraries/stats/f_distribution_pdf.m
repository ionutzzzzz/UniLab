function p = f_distribution_pdf(x, d1, d2)
    % F_DISTRIBUTION_PDF F-distribution probability density function (approximation)
    % This uses the relationship with the Beta function
    p = zeros(size(x));
    idx = x > 0;
    num = sqrt(((d1 .* x(idx)).^d1 .* d2.^d2) ./ (d1 .* x(idx) + d2).^(d1 + d2));
    den = x(idx) .* beta_custom(d1/2, d2/2);
    p(idx) = num ./ den;
end

function b = beta_custom(z, w)
    b = (gamma_stirling(z) * gamma_stirling(w)) / gamma_stirling(z + w);
end
