function [] = bar_plot(y, labels)
    % BAR_PLOT Create an ASCII bar chart
    if nargin < 1, y = []; end
    if nargin < 2
        labels = {};
    end
    
    if ~isempty(labels)
        disp('--- Bar Chart ---');
        for i = 1:length(y)
            if i <= length(labels)
                disp([labels{i}, ': ', num2str(y(i))]);
            end
        end
    end
    terminal_plot(y, [], 20, 60, 'bar');
end
