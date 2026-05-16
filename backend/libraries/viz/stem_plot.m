function [] = stem_plot(y)
    % STEM_PLOT Create an ASCII stem plot
    x = 1:length(y);
    disp('Stem Plot:');
    terminal_plot(y, x, 15, 50);
end
