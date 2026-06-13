function [fb] = bandwidth(sys, db_drop)
    % BANDWIDTH Calculate system bandwidth
    % fb = bandwidth(sys, db_drop) defaults to -3 dB
    if nargin < 1, sys = []; end
    if nargin < 2, db_drop = -3; end
    fb = unilab_bandwidth(sys, db_drop);
end
