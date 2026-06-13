function U = chebyshev_u(n, x)
    if nargin < 1, n = []; end
    if nargin < 2, x = []; end
    if n == 0, U = ones(size(x)); return; end
    if n == 1, U = 2 * x; return; end
    U0 = ones(size(x)); U1 = 2 * x;
    for k = 1:n-1
        U2 = 2 * x .* U1 - U0;
        U0 = U1; U1 = U2;
    end
    U = U1;
end