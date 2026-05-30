function I = gauss_quadrature_2point(f, a, b)
    % GAUSS_QUADRATURE_2POINT 2-point Gaussian quadrature integration on [a, b]
    w1 = 1; w2 = 1;
    x1 = -1/sqrt(3); x2 = 1/sqrt(3);
    
    % Change of variables to [a, b]
    c1 = (b - a) / 2;
    c2 = (b + a) / 2;
    
    I = c1 * (w1 * unilab_call(f, c1*x1 + c2) + w2 * unilab_call(f, c1*x2 + c2));
end
