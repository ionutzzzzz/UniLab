function k = rate_constant_calc(rate, conc_A, order_A, conc_B, order_B)
    % RATE_CONSTANT_CALC Calculate rate constant from rate and concentrations
    % rate = k * [A]^m * [B]^n
    if nargin < 1, rate = []; end
    if nargin < 2, conc_A = []; end
    if nargin < 3, order_A = []; end
    if nargin < 4, conc_B = []; end
    if nargin < 5, order_B = []; end
    if nargin < 4
        k = rate / (conc_A^order_A);
    else
        k = rate / ((conc_A^order_A) * (conc_B^order_B));
    end
end
