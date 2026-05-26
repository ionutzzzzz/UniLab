function pr = page_rank_simple(A, d, max_iters)
    % PAGE_RANK_SIMPLE PageRank algorithm
    if nargin < 2, d = 0.85; end
    if nargin < 3, max_iters = 100; end
    
    n = size(A, 1);
    pr = ones(n, 1) / n;
    
    % Degree normalize A
    D_inv = diag(1 ./ max(sum(A, 2), 1));
    M = (A' * D_inv);
    
    for i = 1:max_iters
        pr_next = (1 - d) / n + d * M * pr;
        if norm(pr_next - pr) < 1e-6
            pr = pr_next;
            break;
        end
        pr = pr_next;
    end
end
