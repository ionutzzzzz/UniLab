function n = npv(rate, values)
    if nargin < 1, rate = []; end
    if nargin < 2, values = []; end
    n = 0;
    for i = 1:length(values)
        n = n + values(i) / (1 + rate)^i;
    end
end