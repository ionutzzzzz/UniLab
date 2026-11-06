function [info] = stepinfo(sys)
    % STEPINFO Extract transient response metrics
    % info = stepinfo(sys) returns a struct with RiseTime, SettlingTime, etc.
    if nargin < 1, sys = []; end
    info = unilab_stepinfo(sys);
end
