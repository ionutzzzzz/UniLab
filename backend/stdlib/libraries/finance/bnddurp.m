function d = bnddurp(cash_flows, times, yield_rate)
    % BNDDURP Macaulay duration (wrapper)
    if nargin < 1, cash_flows = []; end
    if nargin < 2, times = []; end
    if nargin < 3, yield_rate = []; end
    d = macaulay_duration(cash_flows, times, yield_rate);
end
