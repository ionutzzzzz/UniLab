function roe = return_on_equity(net_income, shareholders_equity)
    if nargin < 1, net_income = []; end
    if nargin < 2, shareholders_equity = []; end
    roe = net_income / shareholders_equity;
end
