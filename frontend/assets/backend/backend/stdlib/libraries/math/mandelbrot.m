function [M] = mandelbrot(h, w, max_iter)
    % MANDELBROT Generate a Mandelbrot set visualization grid
    
    M = zeros(h, w);
    for i = 1:h
        for j = 1:w
            c = (-2.0 + (j-1)*3.0/(w-1)) + (-1.0 + (i-1)*2.0/(h-1))*1i;
            z = 0;
            for k = 1:max_iter
                z = z*z + c;
                if abs(z) > 2
                    M(i, j) = k;
                    break;
                end
            end
        end
    end
end
