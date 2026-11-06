function delta_Tf = freezing_point_depression(i, Kf, m)
    % FREEZING_POINT_DEPRESSION Calculate the change in freezing point
    % delta_Tf = freezing_point_depression(i, Kf, m)
    % i: van't Hoff factor, Kf: cryoscopic constant, m: molality
    
    if nargin < 1, i = []; end
    if nargin < 2, Kf = []; end
    if nargin < 3, m = []; end
    delta_Tf = i * Kf * m;
end
