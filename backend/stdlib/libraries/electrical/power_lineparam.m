function [R, L, C] = power_lineparam(length_km, rho, r, D_eq)
    % POWER_LINEPARAM Computes R, L, C parameters for a transmission line
    % [R, L, C] = power_lineparam(length_km, rho, r, D_eq)
    % rho: resistivity, r: conductor radius, D_eq: equivalent distance between phases
    
    if nargin < 3, r = 0.01; end % 1cm
    if nargin < 4, D_eq = 1.0; end % 1m
    
    mu0 = 4 * pi() * 1e-7;
    eps0 = 8.854e-12;
    
    % Resistance
    A = pi() * r^2;
    R = (rho * length_km * 1000) / A;
    
    % Inductance (Self + Mutual approx)
    % r_prime for GMR approx
    r_prime = 0.7788 * r;
    L = (mu0 / (2 * pi())) * log(D_eq / r_prime) * length_km * 1000;
    
    % Capacitance
    C = (2 * pi() * eps0 / log(D_eq / r)) * length_km * 1000;
end
