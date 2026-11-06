function v = prism_volume(base_area, h)
    % PRISM_VOLUME Volume of a prism
    if nargin < 1, base_area = []; end
    if nargin < 2, h = []; end
    v = base_area * h;
end
