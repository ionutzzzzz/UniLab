function npm = net_profit_margin(net_income, revenue)
    if nargin < 1, net_income = []; end
    if nargin < 2, revenue = []; end
    npm = net_income / revenue;
end
