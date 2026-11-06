function r = hypot(x, y)
    % HYPOT Robust square root of sum of squares
    % r = sqrt(abs(x).^2 + abs(y).^2)
    if nargin < 1, x = []; end
    if nargin < 2, y = []; end
    x = abs(x);
    y = abs(y);
    if x == 0 && y == 0
        r = 0;
    else
        max_val = max(x, y);
        min_val = min(x, y);
        r = max_val * sqrt(1 + (min_val / max_val)^2);
    end
end
