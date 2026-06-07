function p = chi_square_pdf(x, k)
    % CHI_SQUARE_PDF Chi-square distribution PDF
    p = zeros(size(x));
    idx = x > 0;
    p(idx) = (1 / (2^(k/2) * gamma_stirling(k/2))) * x(idx).^(k/2 - 1) .* exp(-x(idx)/2);
end
