function [Z] = peaks(N)
    % PEAKS Generate a surface resembling a mountain range (MATLAB-like)
    if nargin < 1, N = 49; end
    
    [X, Y] = meshgrid(linspace(-3, 3, N));
    
    Z = 3*(1-X).^2.*exp(-(X.^2) - (Y+1).^2) ...
       - 10*(X/5 - X.^3 - Y.^5).*exp(-X.^2-Y.^2) ...
       - 1/3*exp(-(X+1).^2 - Y.^2);
end
