function [] = stem_plot(y)
    % STEM_PLOT Create an ASCII stem plot
    x = 1:length(y);
    terminal_plot(y, x, 20, 60, 'stem');
end
