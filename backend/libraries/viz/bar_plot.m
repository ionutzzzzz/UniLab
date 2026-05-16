function [] = bar_plot(y, labels)
    % BAR_PLOT Create an ASCII bar chart
    n = length(y);
    max_val = max(y);
    width = 40;
    
    disp('--- Bar Chart ---');
    for i = 1:n
        bar_len = round((y(i) / max_val) * width);
        bar_str = '';
        for j = 1:bar_len
            bar_str = [bar_str, '#'];
        end
        
        if nargin > 1
            disp([labels{i}, ': ', bar_str, ' (', num2str(y(i)), ')']);
        else
            disp(['Item ', num2str(i), ': ', bar_str, ' (', num2str(y(i)), ')']);
        end
    end
    disp('-----------------');
end
