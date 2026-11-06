function P2 = clausius_clapeyron_relation(P1, T1, T2, delta_H, R)
    % CLAUSIUS_CLAPEYRON_RELATION Calculate vapor pressure at T2
    % ln(P2/P1) = -(delta_H / R) * (1/T2 - 1/T1)
    if nargin < 1, P1 = []; end
    if nargin < 2, T1 = []; end
    if nargin < 3, T2 = []; end
    if nargin < 4, delta_H = []; end
    if nargin < 5, R = 8.314462618; end
    P2 = P1 * exp(-(delta_H / R) * (1/T2 - 1/T1));
end
