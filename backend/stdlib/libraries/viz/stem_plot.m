function [] = stem_plot(y)
    % STEM_PLOT Create an ASCII stem plot
    if nargin < 1, y = []; end
    x = 1:length(y);
    terminal_plot(y, x, 20, 60, 'stem');
end
