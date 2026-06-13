function [c] = set_union(a, b)
    % SET_UNION Union of two sets
    
    if nargin < 1, a = []; end
    if nargin < 2, b = []; end
    c = unique([a(:); b(:)]);
end
