function p = bond_price_calc(par, coupon_rate, ytm, years, freq)
    % BOND_PRICE_CALC Price of a coupon bond
    if nargin < 5, freq = 2; end
    c = par * coupon_rate / freq;
    r = ytm / freq;
    n = years * freq;
    
    p = c * (1 - (1 + r)^-n) / r + par / (1 + r)^n;
end
