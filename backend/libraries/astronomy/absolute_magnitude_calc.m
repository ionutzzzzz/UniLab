function M = absolute_magnitude_calc(m, d)
    % ABSOLUTE_MAGNITUDE_CALC Absolute magnitude given apparent m and distance d in parsecs
    % M = m - 5 * log10(d / 10)
    M = m - 5 * log10_custom(d / 10);
end
