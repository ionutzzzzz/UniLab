function E = planck_law(h, nu)
    if nargin < 1, h = []; end
    if nargin < 2, nu = []; end
    E = h * nu;
end