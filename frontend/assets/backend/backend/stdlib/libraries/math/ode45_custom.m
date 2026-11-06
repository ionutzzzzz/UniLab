function [t, y] = ode45_custom(f, trange, y0)
    if nargin < 1, f = []; end
    if nargin < 2, trange = []; end
    if nargin < 3, y0 = []; end
    [t, y] = ode45(f, trange, y0);
end
