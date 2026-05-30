function p = pv(rate, nper, pmt)
    p = pmt * (1 - (1 + rate)^-nper) / rate;
end