function y = bndyield(price, par, coupon_rate, years, freq)
    % BNDYIELD Yield to maturity of a bond (wrapper for bond_yield_to_maturity)
    if nargin < 1, price = []; end
    if nargin < 2, par = []; end
    if nargin < 3, coupon_rate = []; end
    if nargin < 4, years = []; end
    if nargin < 5, freq = 2; end
    y = bond_yield_to_maturity(price, par, coupon_rate, years, freq);
end
