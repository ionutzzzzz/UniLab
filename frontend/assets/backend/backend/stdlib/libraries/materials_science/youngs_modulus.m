function E = youngs_modulus(sigma, epsilon)
    if nargin < 1, sigma = []; end
    if nargin < 2, epsilon = []; end
    E = sigma / epsilon;
end
