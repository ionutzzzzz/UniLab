function d = rad2deg_custom(r)
    % RAD2DEG_CUSTOM r * 180 / pi
    if nargin < 1, r = []; end
    d = r * 180 / pi;
end
