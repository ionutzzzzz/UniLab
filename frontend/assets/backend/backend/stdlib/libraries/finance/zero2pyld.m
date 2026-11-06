function yields = zero2pyld(zero_rates, periods)
    % ZERO2PYLD Convert zero rates to periodic yields
    % zero_rates: zero rates (annualized)
    % periods: compounding periods per year
    if nargin < 1, zero_rates = []; end
    if nargin < 2, periods = 2; end
    yields = periods .* ((1 + zero_rates).^(1/periods) - 1);
end
