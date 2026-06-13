function A = compound_interest(P, r, n, t)
    if nargin < 1, P = []; end
    if nargin < 2, r = []; end
    if nargin < 3, n = []; end
    if nargin < 4, t = []; end
    A = P * (1 + r/n)^(n*t);
end
