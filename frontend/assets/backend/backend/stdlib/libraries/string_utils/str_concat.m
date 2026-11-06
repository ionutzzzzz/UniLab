function s = str_concat(s1, s2)
    if nargin < 1, s1 = []; end
    if nargin < 2, s2 = []; end
    s = [s1, s2];
end