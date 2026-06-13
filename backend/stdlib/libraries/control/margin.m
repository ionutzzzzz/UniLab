function [gm, pm, w_gm, w_pm] = margin(sys)
    % MARGIN Calculate gain and phase margins
    % [gm, pm, w_gm, w_pm] = margin(sys)
    if nargin < 1, sys = []; end
    [gm, pm, w_gm, w_pm] = unilab_margin(sys);
end
