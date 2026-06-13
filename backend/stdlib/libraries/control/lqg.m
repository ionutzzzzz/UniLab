function [reg] = lqg(sys, Q, R, Qn, Rn)
    % LQG Linear-Quadratic-Gaussian regulator synthesis
    % reg = lqg(sys, Q, R, Qn, Rn)
    if nargin < 1, sys = []; end
    if nargin < 2, Q = []; end
    if nargin < 3, R = []; end
    if nargin < 4, Qn = []; end
    if nargin < 5, Rn = []; end
    reg = unilab_lqg(sys, Q, R, Qn, Rn);
end
