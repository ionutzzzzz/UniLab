function [m] = allmargin(sys)
    % ALLMARGIN Find all stability margins
    % m is a struct with GainerMargin, PhaseMargin, etc.
    if nargin < 1, sys = []; end
    [gm, pm, w_gm, w_pm] = unilab_allmargin(sys);
    m = struct('GainMargin', gm, 'PhaseMargin', pm, 'GMFrequency', w_gm, 'PMFrequency', w_pm);
end
