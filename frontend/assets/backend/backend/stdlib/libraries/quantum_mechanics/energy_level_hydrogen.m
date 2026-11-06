function E = energy_level_hydrogen(n)
    % E in eV
    if nargin < 1, n = []; end
    E = -13.6 / n^2;
end
