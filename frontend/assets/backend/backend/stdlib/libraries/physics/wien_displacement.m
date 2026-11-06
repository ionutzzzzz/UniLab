function lambda_max = wien_displacement(b, T)
    if nargin < 1, b = []; end
    if nargin < 2, T = []; end
    lambda_max = b / T;
end