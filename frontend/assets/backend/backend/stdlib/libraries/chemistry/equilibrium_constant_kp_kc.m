function Kp = equilibrium_constant_kp_kc(Kc, delta_n, T, R)
    % EQUILIBRIUM_CONSTANT_KP_KC Convert Kc to Kp
    % Kp = Kc * (RT)^delta_n
    if nargin < 1, Kc = []; end
    if nargin < 2, delta_n = []; end
    if nargin < 3, T = []; end
    if nargin < 4, R = 0.08206; end % L*atm/(mol*K)
    Kp = Kc * (R * T)^delta_n;
end
