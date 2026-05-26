function c = convexity(cash_flows, times, yield_rate)
    pv_cf = cash_flows ./ (1 + yield_rate).^times;
    c = sum(pv_cf .* (times.^2 + times)) / (sum(pv_cf) * (1 + yield_rate)^2);
end