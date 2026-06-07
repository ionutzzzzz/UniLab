function y = dirac_delta(x)
    y = zeros(size(x));
    y(x == 0) = inf;
end
