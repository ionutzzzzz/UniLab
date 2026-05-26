function [info] = stepinfo(sys)
    % STEPINFO Extract transient response metrics
    % info = stepinfo(sys) returns a struct with RiseTime, SettlingTime, etc.
    info = unilab_stepinfo(sys);
end
