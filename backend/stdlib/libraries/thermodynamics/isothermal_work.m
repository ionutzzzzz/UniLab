function W = isothermal_work(n, R, T, V1, V2)
    if nargin < 1, n = []; end
    if nargin < 2, R = []; end
    if nargin < 3, T = []; end
    if nargin < 4, V1 = []; end
    if nargin < 5, V2 = []; end
    W = n * R * T * log(V2 / V1);
end
