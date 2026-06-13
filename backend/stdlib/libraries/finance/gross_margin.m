function gm = gross_margin(revenue, cogs)
    if nargin < 1, revenue = []; end
    if nargin < 2, cogs = []; end
    gm = (revenue - cogs) / revenue;
end
