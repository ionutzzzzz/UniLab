function de = debt_to_equity(total_liabilities, shareholders_equity)
    if nargin < 1, total_liabilities = []; end
    if nargin < 2, shareholders_equity = []; end
    de = total_liabilities / shareholders_equity;
end
