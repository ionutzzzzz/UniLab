function V = ohm_law(I, R)
    if nargin < 1, I = []; end
    if nargin < 2, R = []; end
    V = I * R;
end
