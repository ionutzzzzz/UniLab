function gamma = lorentz_factor(v, c)
    if nargin < 1, v = []; end
    if nargin < 2, c = []; end
    gamma = 1 / sqrt(1 - (v/c)^2);
end