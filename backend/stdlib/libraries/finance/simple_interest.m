function I = simple_interest(P, r, t)
    if nargin < 1, P = []; end
    if nargin < 2, r = []; end
    if nargin < 3, t = []; end
    I = P * r * t;
end
