function c = bndcon(cash_flows, times, yield_rate)
    % BNDCON Convexity (wrapper)
    c = convexity(cash_flows, times, yield_rate);
end
