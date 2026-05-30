function [x_min, f_min] = fminbnd_custom(f, ax, bx, tol)
    % FMINBND_CUSTOM Find minimum of single-variable function on fixed interval
    % Uses Golden Section Search
    
    if nargin < 4, tol = 1e-6; end
    
    R = (sqrt(5) - 1) / 2; % Golden ratio
    C = 1 - R;
    
    x1 = ax + C * (bx - ax);
    x2 = ax + R * (bx - ax);
    
    f1 = unilab_call(f, x1);
    f2 = unilab_call(f, x2);
    
    while abs(bx - ax) > tol
        if f1 < f2
            bx = x2;
            x2 = x1;
            f2 = f1;
            x1 = ax + C * (bx - ax);
            f1 = unilab_call(f, x1);
        else
            ax = x1;
            x1 = x2;
            f1 = f2;
            x2 = ax + R * (bx - ax);
            f2 = unilab_call(f, x2);
        end
    end
    
    x_min = (ax + bx) / 2;
    f_min = unilab_call(f, x_min);
end
