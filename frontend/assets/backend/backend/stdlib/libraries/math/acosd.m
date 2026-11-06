function y = acosd(x)
    % ACOSD Inverse cosine in degrees
    if nargin < 1, x = []; end
    y = rad2deg_custom(acos(x));
end
