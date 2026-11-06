function b = beta_calc(returns_asset, returns_market)
    if nargin < 1, returns_asset = []; end
    if nargin < 2, returns_market = []; end
    cov_matrix = cov(returns_asset, returns_market);
    b = cov_matrix(1, 2) / var(returns_market);
end