function p = bndprice(par, coupon_rate, ytm, years, freq)
    % BNDPRICE Price of a bond (wrapper for bond_price_calc)
    if nargin < 5, freq = 2; end
    p = bond_price_calc(par, coupon_rate, ytm, years, freq);
end
