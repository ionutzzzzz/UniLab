function p = beta_distribution_pdf(x, a, b)
    % BETA_DISTRIBUTION_PDF Beta distribution PDF
    p = zeros(size(x));
    idx = x > 0 & x < 1;
    B = beta_function(a, b);
    p(idx) = (x(idx).^(a - 1) .* (1 - x(idx)).^(b - 1)) / B;
end
