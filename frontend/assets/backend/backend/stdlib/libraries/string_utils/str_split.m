function c = str_split(str, delimiter)
    if nargin < 1, str = []; end
    if nargin < 2, delimiter = []; end
    c = strsplit(str, delimiter);
end