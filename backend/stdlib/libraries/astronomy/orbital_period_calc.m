function T = orbital_period_calc(mu, a)
    % ORBITAL_PERIOD_CALC Calculate orbital period
    % T = 2 * pi * sqrt(a^3 / mu)
    if nargin < 1, mu = []; end
    if nargin < 2, a = []; end
    T = 2 * pi() * sqrt(a^3 / mu);
end
