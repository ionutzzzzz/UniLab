function [c] = cross_product(a, b)
    % CROSS_PRODUCT 3D cross product of vectors a and b
    
    if nargin < 1, a = []; end
    if nargin < 2, b = []; end
    if length(a) ~= 3 || length(b) ~= 3
        disp('Error: cross_product only supported for 3D vectors.');
        c = [];
        return;
    end
    
    c = [a(2)*b(3) - a(3)*b(2);
         a(3)*b(1) - a(1)*b(3);
         a(1)*b(2) - a(2)*b(1)];
end
