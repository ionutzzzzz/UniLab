function Fb = buoyancy_force(rho_fluid, V_displaced, g)
    if nargin < 1, rho_fluid = []; end
    if nargin < 2, V_displaced = []; end
    if nargin < 3, g = []; end
    Fb = rho_fluid * V_displaced * g;
end
