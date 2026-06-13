function pe = pe_ratio(price_per_share, eps)
    if nargin < 1, price_per_share = []; end
    if nargin < 2, eps = []; end
    pe = price_per_share / eps;
end
