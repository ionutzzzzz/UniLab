function L = laguerre_poly_custom(n, x)
    if nargin < 1, n = []; end
    if nargin < 2, x = []; end
    if n == 0, L = ones(size(x)); return; end
    if n == 1, L = 1 - x; return; end
    L0 = ones(size(x)); L1 = 1 - x;
    for k = 1:n-1
        L2 = ((2*k + 1 - x) .* L1 - k * L0) / (k + 1);
        L0 = L1; L1 = L2;
    end
    L = L1;
end