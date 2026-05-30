function [dv1, dv2, total_dv] = hohmann_transfer(mu, r1, r2)
    % HOHMANN_TRANSFER Calculate delta-v for Hohmann transfer between circular orbits
    % mu: gravitational parameter (G*M)
    v1 = sqrt(mu / r1);
    v2 = sqrt(mu / r2);
    
    v_perigee = sqrt(mu * (2/r1 - 2/(r1+r2)));
    v_apogee = sqrt(mu * (2/r2 - 2/(r1+r2)));
    
    dv1 = abs(v_perigee - v1);
    dv2 = abs(v2 - v_apogee);
    total_dv = dv1 + dv2;
end
