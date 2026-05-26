function [] = hist_plot(data, bins)
    % HIST_PLOT Create an ASCII histogram
    if nargin < 2
        bins = 10;
    end
    
    d_min = min(data);
    d_max = max(data);
    data_range = d_max - d_min;
    bin_width = data_range / bins;
    
    counts = zeros(bins, 1);
    bin_labels = cell(bins, 1);
    
    for i = 1:length(data)
        bin_idx = floor((data(i) - d_min) / bin_width) + 1;
        if bin_idx > bins; bin_idx = bins; end
        counts(bin_idx) = counts(bin_idx) + 1;
    end
    
    for i = 1:bins
        b_start = d_min + (i-1)*bin_width;
        b_end = d_min + i*bin_width;
        bin_labels{i} = [num2str(b_start), '-', num2str(b_end)];
    end
    
    bar_plot(counts, bin_labels);
end
