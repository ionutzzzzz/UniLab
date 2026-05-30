function [y] = taylor_exp(x, a, n)
    % TAYLOR_EXP Taylor series approximation for e^x around point a up to degree n
    % y = sum_{k=0}^n (f^(k)(a) / k!) * (x - a)^k
    % For e^x, f^(k)(a) = e^a
    
    y = zeros(size(x));
    ea = exp(a);
    
    for k = 0:n
        term = (ea / factorial(k)) .* (x - a).^k;
        y = y + term;
    end
end
