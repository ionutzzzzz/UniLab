function y = asin(x)
    % ASIN Inverse sine in radians
    % y = asin(x) = atan2(x, sqrt(1 - x.^2))
    if nargin < 1, x = []; end
    y = atan2(x, sqrt(1 - x.^2));
end
