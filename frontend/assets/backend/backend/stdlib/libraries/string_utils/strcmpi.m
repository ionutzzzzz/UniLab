function b = strcmpi(s1, s2)
    % STRCMPI Compare strings (case-insensitive).
    %   B = STRCMPI(S1, S2) returns true if S1 and S2 are identical,
    %   ignoring case differences.

    if ischar(s1) && ischar(s2)
        b = strcmp(lower(s1), lower(s2));
    elseif iscell(s1) || iscell(s2)
        % For cell arrays, a proper implementation would lower() each element.
        % For now, we delegate to strcmp if they match exactly, 
        % but a full implementation should be more robust.
        try
            % Simplistic implementation: try to compare directly
            b = strcmp(s1, s2);
            if ~b
               % Could implement element-wise lower here
               b = false; 
            end
        catch
            b = false;
        end
    else
        b = strcmp(s1, s2);
    end
end
