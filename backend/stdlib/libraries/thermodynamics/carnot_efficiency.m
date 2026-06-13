function eff = carnot_efficiency(Tc, Th)
    if nargin < 1, Tc = []; end
    if nargin < 2, Th = []; end
    eff = 1 - (Tc / Th);
end
