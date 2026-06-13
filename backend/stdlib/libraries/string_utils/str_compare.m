function b = str_compare(s1, s2)
    if nargin < 1, s1 = []; end
    if nargin < 2, s2 = []; end
    b = strcmp(s1, s2);
end