function [sysc] = canon(sys, type)
    % CANON Transform state-space model to canonical form
    if nargin < 1, sys = []; end
    if nargin < 2, type = 'modal'; end
    sysc = unilab_canon(sys, type);
end
