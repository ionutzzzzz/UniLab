function dS = entropy_change_ideal_gas(n, Cv, T1, T2, R, V1, V2)
    if nargin < 1, n = []; end
    if nargin < 2, Cv = []; end
    if nargin < 3, T1 = []; end
    if nargin < 4, T2 = []; end
    if nargin < 5, R = []; end
    if nargin < 6, V1 = []; end
    if nargin < 7, V2 = []; end
    dS = n * Cv * log(T2/T1) + n * R * log(V2/V1);
end
