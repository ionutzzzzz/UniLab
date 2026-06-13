function ph = ph_calc(h_plus_concentration)
    if nargin < 1, h_plus_concentration = []; end
    ph = -log10_custom(h_plus_concentration);
end
