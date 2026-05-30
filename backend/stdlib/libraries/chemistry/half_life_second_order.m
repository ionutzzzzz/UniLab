function t_half = half_life_second_order(k, A0)
    % HALF_LIFE_SECOND_ORDER Calculate half-life for a second-order reaction
    % t_half = 1 / (k * [A]0)
    t_half = 1 / (k * A0);
end
