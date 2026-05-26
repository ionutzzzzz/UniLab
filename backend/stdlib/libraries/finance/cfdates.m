function dates = cfdates(start_date, years, freq)
    % CFDATES Calculate cash flow dates
    if nargin < 3, freq = 2; end
    n = ceil(years * freq);
    dates = start_date + (1:n) * (365 / freq);
end
