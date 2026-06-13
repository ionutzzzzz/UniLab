function m = trimmed_mean(data, p)
    % TRIMMED_MEAN Mean after discarding p percent of outliers from each end
    if nargin < 1, data = []; end
    if nargin < 2, p = []; end
    n = length(data);
    k = round(n * p / 100);
    sorted_data = sort(data);
    m = mean(sorted_data(k+1 : n-k));
end
