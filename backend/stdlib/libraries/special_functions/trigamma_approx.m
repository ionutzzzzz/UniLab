function y = trigamma_approx(x)
    % Derivative of digamma
    y = 1./x + 1./(2*x.^2) + 1./(6*x.^3) - 1./(30*x.^5);
end