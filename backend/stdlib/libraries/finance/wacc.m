function w = wacc(e, d, re, rd, t)
    v = e + d;
    w = (e/v)*re + (d/v)*rd*(1-t);
end