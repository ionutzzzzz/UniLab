function [sysc] = canon(sys, type)
    % CANON Transform state-space model to canonical form
    if nargin < 2, type = 'modal'; end
    sysc = unilab_canon(sys, type);
end
