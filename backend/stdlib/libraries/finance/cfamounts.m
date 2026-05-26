function [cf, times] = cfamounts(par, coupon_rate, years, freq)
    % CFAMOUNTS Calculate cash flow amounts
    if nargin < 4, freq = 2; end
    n = ceil(years * freq);
    cf = ones(1, n) * (par * coupon_rate / freq);
    cf(end) = cf(end) + par;
    times = (1:n) / freq;
end
