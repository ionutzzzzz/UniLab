function I = newton_cotes_closed(y, h, n)
    % NEWTON_COTES_CLOSED Integration for specific n (1: Trapezoidal, 2: Simpson, etc.)
    if n == 1
        I = (h/2) * (y(1) + y(2));
    elseif n == 2
        I = (h/3) * (y(1) + 4*y(2) + y(3));
    elseif n == 3
        I = (3*h/8) * (y(1) + 3*y(2) + 3*y(3) + y(4));
    else
        I = trapz_custom(y, h); % Fallback
    end
end
