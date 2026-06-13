function A = regular_octagon_area(s)
    if nargin < 1, s = []; end
    A = 2 * (1 + sqrt(2)) * s^2;
end
