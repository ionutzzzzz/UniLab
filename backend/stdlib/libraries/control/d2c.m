function [sysc] = d2c(sysd, method)
    % D2C Convert discrete-time system to continuous-time
    if nargin < 1, sysd = []; end
    if nargin < 2, method = 'zoh'; end
    sysc = unilab_d2c(sysd, method);
end
