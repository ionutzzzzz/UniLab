function P = power_physics(W, t)
    if nargin < 1, W = []; end
    if nargin < 2, t = []; end
    P = W / t;
end
