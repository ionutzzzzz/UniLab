function j = stefan_boltzmann(sigma, T)
    if nargin < 1, sigma = []; end
    if nargin < 2, T = []; end
    j = sigma * T^4;
end