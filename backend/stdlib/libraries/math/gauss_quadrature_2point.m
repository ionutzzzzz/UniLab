function I = gauss_quadrature_2point(f, a, b)
    % GAUSS_QUADRATURE_2POINT 2-point Gauss quadrature
    x1 = -1/sqrt(3);
    x2 = 1/sqrt(3);
    w1 = 1;
    w2 = 1;
    % Transform to [a, b]
    t1 = (b-a)/2 * x1 + (a+b)/2;
    t2 = (b-a)/2 * x2 + (a+b)/2;
    I = (b-a)/2 * (w1 * f(t1) + w2 * f(t2));
end
