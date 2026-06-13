function s = str_replace(str, old_pat, new_pat)
    if nargin < 1, str = []; end
    if nargin < 2, old_pat = []; end
    if nargin < 3, new_pat = []; end
    s = strrep(str, old_pat, new_pat);
end