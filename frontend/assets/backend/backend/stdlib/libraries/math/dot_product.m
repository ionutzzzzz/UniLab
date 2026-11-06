function [d] = dot_product(a, b)
    % DOT_PRODUCT Scalar dot product of vectors a and b
    if nargin < 1, a = []; end
    if nargin < 2, b = []; end
    d = sum(a .* b);
end
