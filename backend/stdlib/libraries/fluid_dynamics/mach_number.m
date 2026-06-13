function Ma = mach_number(v, c)
    if nargin < 1, v = []; end
    if nargin < 2, c = []; end
    Ma = v / c;
end
