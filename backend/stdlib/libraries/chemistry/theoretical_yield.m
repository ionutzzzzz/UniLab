function ty = theoretical_yield(moles_limiting, molar_mass_product, ratio)
    % THEORETICAL_YIELD Calculate theoretical yield in grams
    if nargin < 1, moles_limiting = []; end
    if nargin < 2, molar_mass_product = []; end
    if nargin < 3, ratio = 1; end
    ty = moles_limiting * ratio * molar_mass_product;
end
