function [] = stem_plot(y)
    % STEM_PLOT Create an HD Braille ASCII stem plot
    x = 1:length(y);
    disp('Stem Plot:');
    terminal_plot(y, x, 0, 0, 'stem');
end
