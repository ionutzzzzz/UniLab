function RH = relative_humidity_calc(T, Td)
    % RELATIVE_HUMIDITY_CALC Calculate relative humidity from Temp and Dew Point
    if nargin < 1, T = []; end
    if nargin < 2, Td = []; end
    a = 17.27; b = 237.7;
    numerator = exp((a * Td) / (b + Td));
    denominator = exp((a * T) / (b + T));
    RH = 100 * (numerator / denominator);
end
