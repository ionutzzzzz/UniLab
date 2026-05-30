function [d] = levenshtein_dist(s1, s2)
    % LEVENSHTEIN_DIST Edit distance between two strings
    
    n = length(s1);
    m = length(s2);
    D = zeros(n+1, m+1);
    
    for i = 0:n; D(i+1, 1) = i; end
    for j = 0:m; D(1, j+1) = j; end
    
    for i = 1:n
        for j = 1:m
            if s1(i) == s2(j)
                cost = 0;
            else
                cost = 1;
            end
            D(i+1, j+1) = min([D(i, j+1)+1, D(i+1, j)+1, D(i, j)+cost]);
        end
    end
    d = D(n+1, m+1);
end
