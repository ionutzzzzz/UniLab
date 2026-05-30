function obj = ext2fts(data)
    % EXT2FTS Mock - converts external data to fints
    
    dates = (1:size(data, 1))';
    obj = fints(dates, data);
end
