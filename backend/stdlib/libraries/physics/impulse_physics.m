function J = impulse_physics(F, dt)
    if nargin < 1, F = []; end
    if nargin < 2, dt = []; end
    J = F * dt;
end
