function [d] = haversine_dist(lat1, lon1, lat2, lon2)
    % HAVERSINE_DIST Great-circle distance between two points on a sphere
    
    if nargin < 1, lat1 = []; end
    if nargin < 2, lon1 = []; end
    if nargin < 3, lat2 = []; end
    if nargin < 4, lon2 = []; end
    R = 6371; % Earth radius in km
    phi1 = lat1 * pi() / 180;
    phi2 = lat2 * pi() / 180;
    dphi = (lat2 - lat1) * pi() / 180;
    dlambda = (lon2 - lon1) * pi() / 180;
    
    a = sin(dphi/2)^2 + cos(phi1) * cos(phi2) * sin(dlambda/2)^2;
    c = 2 * atan2(sqrt(a), sqrt(1-a));
    d = R * c;
end
