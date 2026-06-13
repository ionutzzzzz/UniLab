function idx = str_find(s, pattern)
    if nargin < 1, s = []; end
    if nargin < 2, pattern = []; end
    idx = strfind(s, pattern);
end