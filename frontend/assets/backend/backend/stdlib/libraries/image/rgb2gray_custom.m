function gray = rgb2gray_custom(r, g, b)
    if nargin < 1, r = []; end
    if nargin < 2, g = []; end
    if nargin < 3, b = []; end
    gray = 0.2989 * r + 0.5870 * g + 0.1140 * b;
end