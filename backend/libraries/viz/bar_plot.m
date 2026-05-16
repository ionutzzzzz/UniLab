function [] = bar_plot(y, labels)
    % BAR_PLOT Create an HD Braille ASCII bar chart
    if nargin > 1
        disp('--- Bar Chart ---');
        for i = 1:length(y)
            disp([labels{i}, ': ', num2str(y(i))]);
        end
    end
    terminal_plot(y, [0], 0, 0, 'bar');
end
