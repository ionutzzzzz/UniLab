function C = bernoulli_equation_constant(P, rho, v, g, h)
    if nargin < 1, P = []; end
    if nargin < 2, rho = []; end
    if nargin < 3, v = []; end
    if nargin < 4, g = []; end
    if nargin < 5, h = []; end
    C = P + 0.5 * rho * v^2 + rho * g * h;
end
