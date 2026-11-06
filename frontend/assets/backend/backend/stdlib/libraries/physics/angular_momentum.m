function L = angular_momentum(I, omega)
    if nargin < 1, I = []; end
    if nargin < 2, omega = []; end
    L = I * omega;
end
