function epsilon = faraday_law_induction(N, dPhi_dt)
    % FARADAY_LAW_INDUCTION Induced EMF in a coil
    % epsilon = -N * (dPhi / dt)
    if nargin < 1, N = []; end
    if nargin < 2, dPhi_dt = []; end
    epsilon = -N * dPhi_dt;
end
