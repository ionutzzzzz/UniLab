function m = central_moment(data, n)
    % CENTRAL_MOMENT Calculate the n-th central moment
    mu = mean(data);
    m = mean((data - mu).^n);
end
