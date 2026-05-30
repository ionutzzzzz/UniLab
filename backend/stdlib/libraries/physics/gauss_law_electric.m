function Phi = gauss_law_electric(Q_encl, epsilon0)
    % GAUSS_LAW_ELECTRIC Calculate electric flux through a closed surface
    % Phi = Q_encl / epsilon0
    if nargin < 2, epsilon0 = 8.85418782e-12; end
    Phi = Q_encl / epsilon0;
end
