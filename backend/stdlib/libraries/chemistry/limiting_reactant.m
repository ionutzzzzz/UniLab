function [idx, yield] = limiting_reactant(moles_reactants, coeffs)
    % LIMITING_REACTANT Identify the limiting reactant and its max yield
    % yield is in moles of product (assuming 1:1 for the product coefficient)
    if nargin < 1, moles_reactants = []; end
    if nargin < 2, coeffs = []; end
    normalized_moles = moles_reactants ./ coeffs;
    [yield, idx] = min(normalized_moles);
end
