function e = ebitda(net_income, interest, taxes, depreciation, amortization)
    if nargin < 1, net_income = []; end
    if nargin < 2, interest = []; end
    if nargin < 3, taxes = []; end
    if nargin < 4, depreciation = []; end
    if nargin < 5, amortization = []; end
    e = net_income + interest + taxes + depreciation + amortization;
end
