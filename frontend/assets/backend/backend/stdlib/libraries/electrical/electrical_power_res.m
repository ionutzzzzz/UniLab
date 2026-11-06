function P = electrical_power_res(I, R)
    if nargin < 1, I = []; end
    if nargin < 2, R = []; end
    P = I^2 * R;
end
