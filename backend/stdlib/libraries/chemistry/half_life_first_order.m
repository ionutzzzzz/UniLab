function t_half = half_life_first_order(k)
    % HALF_LIFE_FIRST_ORDER Calculate half-life for a first-order reaction
    % t_half = ln(2) / k
    if nargin < 1, k = []; end
    t_half = log(2) / k;
end
