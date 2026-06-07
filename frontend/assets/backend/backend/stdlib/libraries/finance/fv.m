function f = fv(rate, nper, pmt)
    f = pmt * ((1 + rate)^nper - 1) / rate;
end