function fv = annuity_fv(pmt, r, n)
    % ANNUITY_FV Future value of an ordinary annuity
    fv = pmt * ((1 + r)^n - 1) / r;
end
