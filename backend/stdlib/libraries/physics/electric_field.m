function E = electric_field(k, q, r)
    if nargin < 1, k = []; end
    if nargin < 2, q = []; end
    if nargin < 3, r = []; end
    E = k * q / r^2;
end