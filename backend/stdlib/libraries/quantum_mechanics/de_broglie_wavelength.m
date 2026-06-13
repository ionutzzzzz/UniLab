function lambda = de_broglie_wavelength(h, p)
    if nargin < 1, h = []; end
    if nargin < 2, p = []; end
    lambda = h / p;
end
