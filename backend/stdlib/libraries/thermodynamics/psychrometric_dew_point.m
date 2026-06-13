function Td = psychrometric_dew_point(T, RH)
    % PSYCHROMETRIC_DEW_POINT Approximate dew point temperature
    % T in Celsius, RH in percentage
    if nargin < 1, T = []; end
    if nargin < 2, RH = []; end
    a = 17.27; b = 237.7;
    alpha = ((a * T) / (b + T)) + log(RH / 100);
    Td = (b * alpha) / (a - alpha);
end
