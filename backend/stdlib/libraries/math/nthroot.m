function y = nthroot(x, n)
    % NTHROOT Real n-th root of real numbers
    if x < 0
        if mod(n, 2) == 0
            y = nan; % Complex result not supported by nthroot
        else
            y = -(-x)^(1/n);
        end
    else
        y = x^(1/n);
    end
end
