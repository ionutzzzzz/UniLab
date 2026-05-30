function y = acosh(x)
    % ACOSH Inverse hyperbolic cosine
    y = log(x + sqrt(x.^2 - 1));
end
