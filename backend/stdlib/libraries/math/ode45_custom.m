function [t, y] = ode45_custom(f, trange, y0)
    [t, y] = ode45(f, trange, y0);
end
