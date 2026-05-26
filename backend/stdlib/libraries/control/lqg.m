function [reg] = lqg(sys, Q, R, Qn, Rn)
    % LQG Linear-Quadratic-Gaussian regulator synthesis
    % reg = lqg(sys, Q, R, Qn, Rn)
    reg = unilab_lqg(sys, Q, R, Qn, Rn);
end
