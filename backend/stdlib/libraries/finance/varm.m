function model = varm(num_series, lags)
    % VARM Returns a VAR model struct
    
    model.Type = 'VAR';
    model.NumSeries = num_series;
    model.Lags = lags;
    model.Constant = zeros(num_series, 1);
    model.AR = cell(1, lags);
    for i = 1:lags
        model.AR{i} = zeros(num_series, num_series);
    end
    model.Covariance = eye(num_series);
end
