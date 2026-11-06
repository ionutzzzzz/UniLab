function py = percent_yield(actual, theoretical)
    % PERCENT_YIELD Calculate percentage yield
    if nargin < 1, actual = []; end
    if nargin < 2, theoretical = []; end
    py = (actual / theoretical) * 100;
end
