function y = polygamma_approx(m, x)
    % General polygamma for m > 1
    y = (-1)^(m+1) * factorial(m) ./ x.^(m+1);
end