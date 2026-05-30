function eps = eps_calc(net_income, preferred_dividends, outstanding_shares)
    eps = (net_income - preferred_dividends) / outstanding_shares;
end
