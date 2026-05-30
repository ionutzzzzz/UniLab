function [l] = lcm_custom(a, b)
    % LCM_CUSTOM Least Common Multiple
    
    if a == 0 || b == 0
        l = 0;
        return;
    end
    l = abs(a * b) / gcd_custom(a, b);
end
