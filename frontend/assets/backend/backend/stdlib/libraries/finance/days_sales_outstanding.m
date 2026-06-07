function dso = days_sales_outstanding(accounts_receivable, total_credit_sales, number_of_days)
    dso = (accounts_receivable / total_credit_sales) * number_of_days;
end
