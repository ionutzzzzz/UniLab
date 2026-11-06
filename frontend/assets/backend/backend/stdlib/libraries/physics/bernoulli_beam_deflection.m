function y = bernoulli_beam_deflection(P, L, E, I, x)
    % BERNOULLI_BEAM_DEFLECTION Deflection of a cantilever beam with point load at end
    % y = bernoulli_beam_deflection(P, L, E, I, x)
    % P: load, L: length, E: modulus, I: moment of inertia, x: position
    
    if nargin < 1, P = []; end
    if nargin < 2, L = []; end
    if nargin < 3, E = []; end
    if nargin < 4, I = []; end
    if nargin < 5, x = []; end
    y = (P * x.^2) ./ (6 * E * I) .* (3 * L - x);
end
