function p = laplace_pdf(x, mu, b)
    % LAPLACE_PDF Laplace distribution probability density function
    p = (1 / (2 * b)) * exp(-abs(x - mu) / b);
end
