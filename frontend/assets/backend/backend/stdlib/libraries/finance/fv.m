function f = fv(rate, nper, pmt)
    if nargin < 1, rate = []; end
    if nargin < 2, nper = []; end
    if nargin < 3, pmt = []; end
    f = pmt * ((1 + rate)^nper - 1) / rate;
end