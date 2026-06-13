function v = frustum_volume(h, r1, r2)
    % FRUSTUM_VOLUME Volume of a conical frustum
    if nargin < 1, h = []; end
    if nargin < 2, r1 = []; end
    if nargin < 3, r2 = []; end
    v = (1/3) * pi() * h * (r1^2 + r1*r2 + r2^2);
end
