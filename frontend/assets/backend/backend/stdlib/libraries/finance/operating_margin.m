function om = operating_margin(operating_income, revenue)
    if nargin < 1, operating_income = []; end
    if nargin < 2, revenue = []; end
    om = operating_income / revenue;
end
