function n = refractive_index_calc(c, v)
    % REFRACTIVE_INDEX_CALC Calculate refractive index
    % n = c / v
    if nargin < 2, v = []; end
    if nargin < 1, c = 299792458; end
    n = c / v;
end
