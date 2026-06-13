function d = geodesic_distance_sphere(lat1, lon1, lat2, lon2, r)
    % GEODESIC_DISTANCE_SPHERE Great-circle distance on a sphere of radius r
    if nargin < 1, lat1 = []; end
    if nargin < 2, lon1 = []; end
    if nargin < 3, lat2 = []; end
    if nargin < 4, lon2 = []; end
    if nargin < 5, r = 1; end
    d = haversine_dist(lat1, lon1, lat2, lon2);
    % haversine_dist uses Earth radius (6371), adjusting for custom r
    d = d * (r / 6371);
end
