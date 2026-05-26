function y = atanh(x)
    % ATANH Inverse hyperbolic tangent
    y = 0.5 * log((1 + x) ./ (1 - x));
end
