function v = hubble_law(H0, D)
    if nargin < 1, H0 = []; end
    if nargin < 2, D = []; end
    v = H0 * D;
end
