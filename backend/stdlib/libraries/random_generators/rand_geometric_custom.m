function k = rand_geometric_custom(p, n)
    if nargin < 2, n = 1; end
    k = ceil(log(rand(n, 1)) / log(1 - p));
end