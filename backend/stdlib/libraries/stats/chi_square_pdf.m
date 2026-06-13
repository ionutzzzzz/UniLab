function p = chi_square_pdf(x, k)
    % CHI_SQUARE_PDF Chi-square distribution PDF
    if nargin < 1, x = []; end
    if nargin < 2, k = []; end
    p = zeros(size(x));
    idx = x > 0;
    p(idx) = (1 / (2^(k/2) * gamma_stirling(k/2))) * x(idx).^(k/2 - 1) .* exp(-x(idx)/2);
end
