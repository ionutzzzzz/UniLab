function [] = box_plot(data)
    % BOX_PLOT Create an ASCII box plot
    % Using 'bar' as a placeholder for box plot visualization in ASCII
    if nargin < 1, data = []; end
    terminal_plot(data, [], 20, 60, 'bar');
end
