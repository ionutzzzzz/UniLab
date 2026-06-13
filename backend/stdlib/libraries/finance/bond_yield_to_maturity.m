function ytm = bond_yield_to_maturity(price, par, coupon_rate, years, freq)
    % BOND_YIELD_TO_MATURITY Approximate YTM of a bond
    if nargin < 1, price = []; end
    if nargin < 2, par = []; end
    if nargin < 3, coupon_rate = []; end
    if nargin < 4, years = []; end
    if nargin < 5, freq = 2; end
    coupon = par * coupon_rate / freq;
    n = years * freq;
    % Simple approximation formula
    ytm = (coupon + (par - price) / n) / ((par + price) / 2);
    ytm = ytm * freq;
end
