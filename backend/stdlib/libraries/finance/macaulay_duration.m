function d = macaulay_duration(cash_flows, times, yield_rate)
    if nargin < 1, cash_flows = []; end
    if nargin < 2, times = []; end
    if nargin < 3, yield_rate = []; end
    pv_cf = cash_flows ./ (1 + yield_rate).^times;
    weights = pv_cf / sum(pv_cf);
    d = sum(weights .* times);
end