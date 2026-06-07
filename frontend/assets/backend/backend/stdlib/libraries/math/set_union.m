function [c] = set_union(a, b)
    % SET_UNION Union of two sets
    
    c = unique([a(:); b(:)]);
end
