function [] = scatter_plot(x, y, label)
    % SCATTER_PLOT Create an ASCII scatter plot
    if nargin < 3
        label = 'Data';
    end
    disp(['Scatter Plot: ', label]);
    terminal_plot(y, x, 20, 60, 'scatter');
end
