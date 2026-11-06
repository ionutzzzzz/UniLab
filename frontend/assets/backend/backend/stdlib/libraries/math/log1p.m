function y = log1p(x)
    % LOG1P Natural logarithm of 1 + x
    if nargin < 1, x = []; end
    if abs(x) < 1e-4
        y = x - x^2/2 + x^3/3; % Taylor approximation for small x
    else
        y = log(1 + x);
    end
end
