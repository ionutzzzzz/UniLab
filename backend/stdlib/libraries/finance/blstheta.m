function t = blstheta(S, K, T, r, sigma, type)
    % BLSTHETA Option theta wrapper
    if nargin < 1, S = []; end
    if nargin < 2, K = []; end
    if nargin < 3, T = []; end
    if nargin < 4, r = []; end
    if nargin < 5, sigma = []; end
    if nargin < 6, type = 'call'; end
    t = black_scholes_theta(S, K, T, r, sigma, type);
end
