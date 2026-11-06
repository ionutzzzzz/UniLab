function fv = annuity_fv(pmt, r, n)
    % ANNUITY_FV Future value of an ordinary annuity
    if nargin < 1, pmt = []; end
    if nargin < 2, r = []; end
    if nargin < 3, n = []; end
    fv = pmt * ((1 + r)^n - 1) / r;
end
