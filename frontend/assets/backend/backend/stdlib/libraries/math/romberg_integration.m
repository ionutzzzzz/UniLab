function R = romberg_integration(f, a, b, tol)
    % ROMBERG_INTEGRATION Romberg integration
    if nargin < 1, f = []; end
    if nargin < 2, a = []; end
    if nargin < 3, b = []; end
    if nargin < 4, tol = []; end
    h = b - a;
    R = zeros(10, 10);
    R(1,1) = h/2 * (f(a) + f(b));
    for i = 2:10
        h = h / 2;
        sum_f = 0;
        for k = 1:2^(i-2)
            sum_f = sum_f + f(a + (2*k-1)*h);
        end
        R(i,1) = 0.5 * R(i-1,1) + sum_f * h;
        for j = 2:i
            R(i,j) = R(i,j-1) + (R(i,j-1) - R(i-1,j-1)) / (4^(j-1) - 1);
        end
        if abs(R(i,i) - R(i-1,i-1)) < tol
            R = R(i,i);
            return;
        end
    end
    R = R(10,10);
end
