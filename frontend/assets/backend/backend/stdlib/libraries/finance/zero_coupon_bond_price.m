function p = zero_coupon_bond_price(par, r, t)
    % ZERO_COUPON_BOND_PRICE Price of a zero-coupon bond
    % p = par / (1 + r)^t
    if nargin < 1, par = []; end
    if nargin < 2, r = []; end
    if nargin < 3, t = []; end
    p = par / (1 + r)^t;
end
