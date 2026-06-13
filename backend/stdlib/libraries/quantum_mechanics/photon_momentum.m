function p = photon_momentum(h, lambda)
    if nargin < 1, h = []; end
    if nargin < 2, lambda = []; end
    p = h / lambda;
end
