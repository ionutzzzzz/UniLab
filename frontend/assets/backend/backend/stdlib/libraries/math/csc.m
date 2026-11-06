function y = csc(x)
    % CSC Cosecant in radians
    if nargin < 1, x = []; end
    y = 1 ./ sin(x);
end
