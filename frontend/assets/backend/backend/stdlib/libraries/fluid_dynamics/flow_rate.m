function Q = flow_rate(A, v)
    if nargin < 1, A = []; end
    if nargin < 2, v = []; end
    Q = A * v;
end
