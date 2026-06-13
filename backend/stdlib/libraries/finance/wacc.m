function w = wacc(e, d, re, rd, t)
    if nargin < 1, e = []; end
    if nargin < 2, d = []; end
    if nargin < 3, re = []; end
    if nargin < 4, rd = []; end
    if nargin < 5, t = []; end
    v = e + d;
    w = (e/v)*re + (d/v)*rd*(1-t);
end