function M = molarity(moles_solute, liters_solution)
    if nargin < 1, moles_solute = []; end
    if nargin < 2, liters_solution = []; end
    M = moles_solute / liters_solution;
end
