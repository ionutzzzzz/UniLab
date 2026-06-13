function roa = return_on_assets(net_income, total_assets)
    if nargin < 1, net_income = []; end
    if nargin < 2, total_assets = []; end
    roa = net_income / total_assets;
end
