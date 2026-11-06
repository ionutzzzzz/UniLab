function cr = current_ratio(current_assets, current_liabilities)
    if nargin < 1, current_assets = []; end
    if nargin < 2, current_liabilities = []; end
    cr = current_assets / current_liabilities;
end
