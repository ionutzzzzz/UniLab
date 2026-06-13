function m = molality(moles_solute, kg_solvent)
    if nargin < 1, moles_solute = []; end
    if nargin < 2, kg_solvent = []; end
    m = moles_solute / kg_solvent;
end
