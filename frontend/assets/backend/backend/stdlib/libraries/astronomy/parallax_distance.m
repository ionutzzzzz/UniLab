function d = parallax_distance(p)
    % PARALLAX_DISTANCE Calculate distance in parsecs from parallax in arcseconds
    % d = parallax_distance(p)
    
    if nargin < 1, p = []; end
    d = 1 / p;
end
