function Td = psychrometric_dew_point(T, RH)
    % PSYCHROMETRIC_DEW_POINT Approximate dew point temperature
    % T in Celsius, RH in percentage
    a = 17.27; b = 237.7;
    alpha = ((a * T) / (b + T)) + log(RH / 100);
    Td = (b * alpha) / (a - alpha);
end
