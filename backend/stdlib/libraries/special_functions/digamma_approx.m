function y = digamma_approx(x)
    % Asymptotic expansion
    y = log(x) - 1./(2*x) - 1./(12*x.^2) + 1./(120*x.^4);
end