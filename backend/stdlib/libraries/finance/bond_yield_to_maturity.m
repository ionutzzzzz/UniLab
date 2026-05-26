function ytm = bond_yield_to_maturity(price, par, coupon_rate, years, freq)
    % BOND_YIELD_TO_MATURITY Approximate YTM of a bond
    if nargin < 5, freq = 2; end
    coupon = par * coupon_rate / freq;
    n = years * freq;
    % Simple approximation formula
    ytm = (coupon + (par - price) / n) / ((par + price) / 2);
    ytm = ytm * freq;
end
