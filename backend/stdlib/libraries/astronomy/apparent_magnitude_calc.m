function m = apparent_magnitude_calc(M, d)
    % APPARENT_MAGNITUDE_CALC Apparent magnitude given absolute M and distance d in parsecs
    % m = M + 5 * log10(d / 10)
    m = M + 5 * log10_custom(d / 10);
end
