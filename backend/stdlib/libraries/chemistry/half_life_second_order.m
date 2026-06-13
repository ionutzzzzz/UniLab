function t_half = half_life_second_order(k, A0)
    % HALF_LIFE_SECOND_ORDER Calculate half-life for a second-order reaction
    % t_half = 1 / (k * [A]0)
    if nargin < 1, k = []; end
    if nargin < 2, A0 = []; end
    t_half = 1 / (k * A0);
end
