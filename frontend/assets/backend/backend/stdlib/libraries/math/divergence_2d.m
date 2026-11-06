function [div] = divergence_2d(Fx, Fy, dx, dy)
    % DIVERGENCE_2D Numerical divergence of a 2D vector field
    % div = dFx/dx + dFy/dy
    
    if nargin < 1, Fx = []; end
    if nargin < 2, Fy = []; end
    if nargin < 3, dx = []; end
    if nargin < 4, dy = []; end
    [dFxx, dFxy] = gradient_2d(Fx, dx, dy);
    [dFyx, dFyy] = gradient_2d(Fy, dx, dy);
    
    div = dFxx + dFyy;
end
