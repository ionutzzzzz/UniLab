function b = beta_calc(returns_asset, returns_market)
    cov_matrix = cov(returns_asset, returns_market);
    b = cov_matrix(1, 2) / var(returns_market);
end