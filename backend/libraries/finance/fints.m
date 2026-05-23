function obj = fints(dates, data, names)
    % FINTS Returns a struct with dates and data
    
    if nargin < 3
        names = {'Data'};
    end
    obj.dates = dates;
    obj.data = data;
    obj.names = names;
    obj.desc = 'Financial Time Series';
end
