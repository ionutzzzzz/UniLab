function [c] = convolution_num(f, g, h)
    % CONVOLUTION_NUM Numerical convolution of two signals
    % (f * g)(t) = integral f(tau) g(t - tau) d tau
    
    if nargin < 1, f = []; end
    if nargin < 2, g = []; end
    if nargin < 3, h = []; end
    n_f = length(f);
    n_g = length(g);
    n_c = n_f + n_g - 1;
    c = zeros(n_c, 1);
    
    for i = 1:n_c
        sum_val = 0;
        for j = 1:n_f
            k = i - j + 1;
            if k >= 1 && k <= n_g
                sum_val = sum_val + f(j) * g(k);
            end
        end
        c(i) = sum_val * h;
    end
end
