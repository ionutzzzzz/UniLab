function [z, p, k] = zpkdata(sys)
    % ZPKDATA Extract zero-pole-gain data
    % [z, p, k] = zpkdata(sys)
    if nargin < 1, sys = []; end
    [z, p, k] = unilab_zpkdata(sys);
end
