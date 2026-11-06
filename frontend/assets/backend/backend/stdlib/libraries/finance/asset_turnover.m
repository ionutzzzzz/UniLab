function at = asset_turnover(revenue, average_total_assets)
    if nargin < 1, revenue = []; end
    if nargin < 2, average_total_assets = []; end
    at = revenue / average_total_assets;
end
