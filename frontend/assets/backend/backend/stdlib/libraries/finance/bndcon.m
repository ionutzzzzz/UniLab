function c = bndcon(cash_flows, times, yield_rate)
    % BNDCON Convexity (wrapper)
    if nargin < 1, cash_flows = []; end
    if nargin < 2, times = []; end
    if nargin < 3, yield_rate = []; end
    c = convexity(cash_flows, times, yield_rate);
end
