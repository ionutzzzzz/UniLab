function [] = stairs_plot(x, y)
    % STAIRS_PLOT Create an ASCII stairs plot
    if nargin < 2
        y = x;
        x = 1:length(y);
    end
    terminal_plot(y, x, 20, 60, 'stairs');
end
