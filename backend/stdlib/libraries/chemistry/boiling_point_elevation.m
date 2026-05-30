function delta_Tb = boiling_point_elevation(i, Kb, m)
    % BOILING_POINT_ELEVATION Calculate the change in boiling point
    % delta_Tb = boiling_point_elevation(i, Kb, m)
    % i: van't Hoff factor, Kb: ebullioscopic constant, m: molality
    
    delta_Tb = i * Kb * m;
end
