function ty = theoretical_yield(moles_limiting, molar_mass_product, ratio)
    % THEORETICAL_YIELD Calculate theoretical yield in grams
    if nargin < 3, ratio = 1; end
    ty = moles_limiting * ratio * molar_mass_product;
end
