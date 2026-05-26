function [gm, pm, w_gm, w_pm] = margin(sys)
    % MARGIN Calculate gain and phase margins
    % [gm, pm, w_gm, w_pm] = margin(sys)
    [gm, pm, w_gm, w_pm] = unilab_margin(sys);
end
