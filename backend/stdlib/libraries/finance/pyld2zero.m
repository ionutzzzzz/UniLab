function zero_rates = pyld2zero(periodic_yields, periods)
    % PYLD2ZERO Convert periodic yields to zero rates
    % periodic_yields: yields with specific compounding
    % periods: compounding periods per year
    if nargin < 2, periods = 2; end
    zero_rates = (1 + periodic_yields ./ periods).^periods - 1;
end
