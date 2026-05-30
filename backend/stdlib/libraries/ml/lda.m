function [W] = lda(X, y, num_components)
    % LDA Linear Discriminant Analysis
    
    if nargin < 3, num_components = size(X, 2); end
    
    classes = unique(y);
    num_classes = length(classes);
    [m, n] = size(X);
    
    mean_overall = mean(X, 1);
    
    S_W = zeros(n, n);
    S_B = zeros(n, n);
    
    for i = 1:num_classes
        c = classes(i);
        X_c = X(y == c, :);
        mean_c = mean(X_c, 1);
        
        % Within-class scatter
        diff_c = X_c - mean_c;
        S_W = S_W + diff_c' * diff_c;
        
        % Between-class scatter
        n_c = size(X_c, 1);
        mean_diff = mean_c - mean_overall;
        S_B = S_B + n_c * (mean_diff' * mean_diff);
    end
    
    % Solve generalized eigenvalue problem: S_W^-1 * S_B
    matrix_to_solve = inv(S_W) * S_B;
    [V, D] = eig(matrix_to_solve);
    
    % Sort eigenvectors by eigenvalues
    eigenvalues = diag(D);
    [~, sort_idx] = sort(eigenvalues);
    sort_idx = sort_idx(end:-1:1); % Descending
    
    W = real(V(:, sort_idx(1:num_components)));
end
