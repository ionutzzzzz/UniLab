function n = norm_mat(A, type)
    % NORM_MAT Matrix norm
    if nargin < 1, A = []; end
    if nargin < 2, type = 2; end
    if ischar(type)
        if strcmp(type, 'fro')
            n = sqrt(sum(sum(A.^2)));
        elseif strcmp(type, 'inf')
            n = max(sum(abs(A), 2));
        end
    elseif type == 1
        n = max(sum(abs(A), 1));
    elseif type == 2
        [~, S, ~] = svd(A);
        n = max(diag(S));
    end
end
