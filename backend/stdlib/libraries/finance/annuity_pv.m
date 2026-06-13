function pv = annuity_pv(pmt, r, n)
    % ANNUITY_PV Present value of an ordinary annuity
    if nargin < 1, pmt = []; end
    if nargin < 2, r = []; end
    if nargin < 3, n = []; end
    pv = pmt * (1 - (1 + r)^-n) / r;
end
