function it = inventory_turnover(cogs, average_inventory)
    if nargin < 1, cogs = []; end
    if nargin < 2, average_inventory = []; end
    it = cogs / average_inventory;
end
