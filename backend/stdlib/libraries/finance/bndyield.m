function y = bndyield(price, par, coupon_rate, years, freq)
    % BNDYIELD Yield to maturity of a bond (wrapper for bond_yield_to_maturity)
    if nargin < 5, freq = 2; end
    y = bond_yield_to_maturity(price, par, coupon_rate, years, freq);
end
