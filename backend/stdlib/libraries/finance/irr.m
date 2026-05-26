function r = irr(values)
    r = 0.1;
    for iter = 1:100
        npv_val = npv(r, values);
        if abs(npv_val) < 1e-5; break; end
        r = r + 0.01 * sign(npv_val);
    end
end