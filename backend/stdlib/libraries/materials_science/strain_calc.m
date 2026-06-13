function epsilon = strain_calc(dL, L0)
    if nargin < 1, dL = []; end
    if nargin < 2, L0 = []; end
    epsilon = dL / L0;
end
