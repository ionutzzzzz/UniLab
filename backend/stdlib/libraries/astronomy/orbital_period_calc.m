function T = orbital_period_calc(mu, a)
    % ORBITAL_PERIOD_CALC Calculate orbital period
    % T = 2 * pi * sqrt(a^3 / mu)
    T = 2 * pi() * sqrt(a^3 / mu);
end
