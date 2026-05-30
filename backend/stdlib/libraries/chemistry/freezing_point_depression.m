function delta_Tf = freezing_point_depression(i, Kf, m)
    % FREEZING_POINT_DEPRESSION Calculate the change in freezing point
    % delta_Tf = freezing_point_depression(i, Kf, m)
    % i: van't Hoff factor, Kf: cryoscopic constant, m: molality
    
    delta_Tf = i * Kf * m;
end
