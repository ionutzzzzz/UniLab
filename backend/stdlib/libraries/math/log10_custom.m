function y = log10_custom(x)
    % LOG10_CUSTOM log(x) / log(10)
    if nargin < 1, x = []; end
    y = log(x) / log(10);
end
