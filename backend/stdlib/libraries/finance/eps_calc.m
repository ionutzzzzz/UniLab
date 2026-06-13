function eps = eps_calc(net_income, preferred_dividends, outstanding_shares)
    if nargin < 1, net_income = []; end
    if nargin < 2, preferred_dividends = []; end
    if nargin < 3, outstanding_shares = []; end
    eps = (net_income - preferred_dividends) / outstanding_shares;
end
