function dso = days_sales_outstanding(accounts_receivable, total_credit_sales, number_of_days)
    if nargin < 1, accounts_receivable = []; end
    if nargin < 2, total_credit_sales = []; end
    if nargin < 3, number_of_days = []; end
    dso = (accounts_receivable / total_credit_sales) * number_of_days;
end
