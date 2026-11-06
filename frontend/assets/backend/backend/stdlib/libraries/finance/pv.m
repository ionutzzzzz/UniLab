function p = pv(rate, nper, pmt)
    if nargin < 1, rate = []; end
    if nargin < 2, nper = []; end
    if nargin < 3, pmt = []; end
    p = pmt * (1 - (1 + rate)^-nper) / rate;
end