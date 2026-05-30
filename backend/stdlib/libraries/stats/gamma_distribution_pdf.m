function p = gamma_distribution_pdf(x, a, b)
    % GAMMA_DISTRIBUTION_PDF Gamma distribution PDF (shape a, scale b)
    p = zeros(size(x));
    idx = x > 0;
    p(idx) = (1 / (b^a * gamma_stirling(a))) * x(idx).^(a - 1) .* exp(-x(idx)/b);
end
