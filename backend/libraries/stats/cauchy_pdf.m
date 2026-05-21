function p = cauchy_pdf(x, x0, gamma)
    % CAUCHY_PDF Cauchy distribution probability density function
    p = 1 / (pi() * gamma * (1 + ((x - x0) / gamma)^2));
end
