function [c] = set_intersect(a, b)
    % SET_INTERSECT Intersection of two sets
    
    a = a(:);
    b = b(:);
    
    mask = zeros(size(a));
    for i = 1:length(a)
        if any(b == a(i))
            mask(i) = 1;
        end
    end
    c = unique(a(mask == 1));
end
