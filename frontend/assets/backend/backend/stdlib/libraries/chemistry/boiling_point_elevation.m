function delta_Tb = boiling_point_elevation(i, Kb, m)
    % BOILING_POINT_ELEVATION Calculate the change in boiling point
    % delta_Tb = boiling_point_elevation(i, Kb, m)
    % i: van't Hoff factor, Kb: ebullioscopic constant, m: molality
    
    if nargin < 1, i = []; end
    if nargin < 2, Kb = []; end
    if nargin < 3, m = []; end
    delta_Tb = i * Kb * m;
end
