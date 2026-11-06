function eff = otto_cycle_efficiency(r, gamma)
    % OTTO_CYCLE_EFFICIENCY Theoretical efficiency of an Otto cycle
    % r: compression ratio, gamma: ratio of specific heats
    if nargin < 1, r = []; end
    if nargin < 2, gamma = []; end
    eff = 1 - (1 / r^(gamma - 1));
end
