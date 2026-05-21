function d = macaulay_duration(cash_flows, times, yield_rate)
    pv_cf = cash_flows ./ (1 + yield_rate).^times;
    weights = pv_cf / sum(pv_cf);
    d = sum(weights .* times);
end