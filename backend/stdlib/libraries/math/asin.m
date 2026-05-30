function y = asin(x)
    % ASIN Inverse sine in radians
    % y = asin(x) = atan2(x, sqrt(1 - x.^2))
    y = atan2(x, sqrt(1 - x.^2));
end
