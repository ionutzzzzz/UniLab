function n = npv(rate, values)
    n = 0;
    for i = 1:length(values)
        n = n + values(i) / (1 + rate)^i;
    end
end