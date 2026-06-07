function y = acos(x)
    % ACOS Inverse cosine in radians
    % y = acos(x) = atan2(sqrt(1 - x.^2), x)
    y = atan2(sqrt(1 - x.^2), x);
end
