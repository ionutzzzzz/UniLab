function p = bndprice(par, coupon_rate, ytm, years, freq)
    % BNDPRICE Price of a bond (wrapper for bond_price_calc)
    if nargin < 1, par = []; end
    if nargin < 2, coupon_rate = []; end
    if nargin < 3, ytm = []; end
    if nargin < 4, years = []; end
    if nargin < 5, freq = 2; end
    p = bond_price_calc(par, coupon_rate, ytm, years, freq);
end
