function d = point_to_plane_distance_3d(px, py, pz, a, b, c, d_plane)
    % POINT_TO_PLANE_DISTANCE_3D Distance from point to plane ax + by + cz + d = 0
    if nargin < 1, px = []; end
    if nargin < 2, py = []; end
    if nargin < 3, pz = []; end
    if nargin < 4, a = []; end
    if nargin < 5, b = []; end
    if nargin < 6, c = []; end
    if nargin < 7, d_plane = []; end
    num = abs(a*px + b*py + c*pz + d_plane);
    den = sqrt(a^2 + b^2 + c^2);
    d = num / den;
end
