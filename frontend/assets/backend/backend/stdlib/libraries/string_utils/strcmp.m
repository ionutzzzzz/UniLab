function b = strcmp(s1, s2)
    % STRCMP Compare strings.
    %   B = STRCMP(S1, S2) returns true if S1 and S2 are identical.
    %   Supports character arrays and cell arrays of strings.

    if nargin < 1, s1 = []; end
    if nargin < 2, s2 = []; end
    if ischar(s1) && ischar(s2)
        b = isequal(s1, s2);
    elseif iscell(s1) || iscell(s2)
        % For cell arrays, we perform element-wise comparison if possible
        % or return false if they are incompatible.
        try
            b = isequal(s1, s2);
        catch
            b = false;
        end
    else
        b = isequal(s1, s2);
    end
end
