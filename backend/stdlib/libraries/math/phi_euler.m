function [phi] = phi_euler(n)
    % PHI_EULER Euler's totient function
    
    phi = n;
    temp = n;
    d = 2;
    while d * d <= temp
        if mod(temp, d) == 0
            while mod(temp, d) == 0
                temp = temp / d;
            end
            phi = phi * (1 - 1/d);
        end
        d = d + 1;
    end
    if temp > 1
        phi = phi * (1 - 1/temp);
    end
end
