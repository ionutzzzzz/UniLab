function T = star_temperature_wien(lambda_max)
    % STAR_TEMPERATURE_WIEN Temperature from peak wavelength
    % T = b / lambda_max
    b = 2.897771955e-3;
    T = b / lambda_max;
end
