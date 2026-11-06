function c = cagr(bv, ev, n)
    if nargin < 1, bv = []; end
    if nargin < 2, ev = []; end
    if nargin < 3, n = []; end
    c = (ev / bv)^(1 / n) - 1;
end