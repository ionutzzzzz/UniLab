function a = circle_area(r)
    if nargin < 1, r = []; end
    a = pi() * r^2;
end