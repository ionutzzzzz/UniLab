function obj = ascii2fts(filename)
    % ASCII2FTS Mock - reads a CSV file
    
    fprintf('Reading time series from %s...\n', filename);
    % Mock data
    dates = (1:10)';
    data = rand(10, 1);
    obj = fints(dates, data, {'Asset1'});
end
