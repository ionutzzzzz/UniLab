function [yi, a, b, c, d] = cubic_spline_interp(x, y, xi)
    % CUBIC_SPLINE_INTERP Natural cubic spline interpolation
    if nargin < 1, x = []; end
    if nargin < 2, y = []; end
    if nargin < 3, xi = []; end
    n = length(x) - 1;
    h = diff(x);
    
    alpha = zeros(n, 1);
    for i = 2:n
        alpha(i) = (3/h(i))*(y(i+1)-y(i)) - (3/h(i-1))*(y(i)-y(i-1));
    end
    
    l = ones(n+1, 1); mu = zeros(n+1, 1); z = zeros(n+1, 1);
    for i = 2:n
        l(i) = 2*(x(i+1)-x(i-1)) - h(i-1)*mu(i-1);
        mu(i) = h(i)/l(i);
        z(i) = (alpha(i)-h(i-1)*z(i-1))/l(i);
    end
    
    l(n+1) = 1; z(n+1) = 0; c = zeros(n+1, 1);
    b = zeros(n, 1); d = zeros(n, 1); a = y(1:n);
    
    for j = n:-1:1
        c(j) = z(j) - mu(j)*c(j+1);
        b(j) = (y(j+1)-y(j))/h(j) - h(j)*(c(j+1)+2*c(j))/3;
        d(j) = (c(j+1)-c(j))/(3*h(j));
    end
    
    % Evaluation at xi
    yi = zeros(size(xi));
    for k = 1:length(xi)
        idx = find(x <= xi(k), 1, 'last');
        if isempty(idx), idx = 1; elseif idx > n, idx = n; end
        dx = xi(k) - x(idx);
        yi(k) = a(idx) + b(idx)*dx + c(idx)*dx^2 + d(idx)*dx^3;
    end
end
