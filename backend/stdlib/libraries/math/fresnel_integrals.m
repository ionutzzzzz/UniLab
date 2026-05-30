function [S, C] = fresnel_integrals(x, n)
    % FRESNEL_INTEGRALS Power series approximation of Fresnel integrals
    % S(x) = integral_0^x sin(pi*t^2 / 2) dt
    % C(x) = integral_0^x cos(pi*t^2 / 2) dt
    
    S = zeros(size(x));
    C = zeros(size(x));
    
    for k = 0:n
        term_s = ((-1)^k .* (pi()/2)^(2*k+1) .* x.^(4*k+3)) ./ (factorial(2*k+1) * (4*k+3));
        term_c = ((-1)^k .* (pi()/2)^(2*k) .* x.^(4*k+1)) ./ (factorial(2*k) * (4*k+1));
        S = S + term_s;
        C = C + term_c;
    end
end
