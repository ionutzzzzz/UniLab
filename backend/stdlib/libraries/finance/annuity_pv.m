function pv = annuity_pv(pmt, r, n)
    % ANNUITY_PV Present value of an ordinary annuity
    pv = pmt * (1 - (1 + r)^-n) / r;
end
