function [] = heatmap(M)
    % HEATMAP Create an ASCII heatmap for a matrix
    if nargin < 1, M = []; end
    terminal_heatmap(M);
end
