function [z] = bessel_j0_approx(x, n)
    % BESSEL_J0_APPROX Power series approximation of Bessel function of the first kind J_0(x)
    % J_0(x) = sum_{k=0}^inf ((-1)^k / (k!)^2) * (x/2)^{2k}
    
    z = zeros(size(x));
    for k = 0:n
        term = ((-1)^k / (factorial(k)^2)) .* (x ./ 2).^(2 * k);
        z = z + term;
    end
end
