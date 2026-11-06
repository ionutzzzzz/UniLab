function [sys] = series(sys1, sys2)
    if nargin < 1, sys1 = []; end
    if nargin < 2, sys2 = []; end
    sys = unilab_series(sys1, sys2);
end