function d = bnddurp(cash_flows, times, yield_rate)
    % BNDDURP Macaulay duration (wrapper)
    d = macaulay_duration(cash_flows, times, yield_rate);
end
