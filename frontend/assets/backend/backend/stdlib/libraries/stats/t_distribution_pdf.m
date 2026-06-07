function p = t_distribution_pdf(x, nu)
    % T_DISTRIBUTION_PDF Student's t-distribution probability density function
    coeff = gamma_stirling((nu + 1) / 2) / (sqrt(nu * pi()) * gamma_stirling(nu / 2));
    p = coeff * (1 + (x.^2) / nu).^(-(nu + 1) / 2);
end
