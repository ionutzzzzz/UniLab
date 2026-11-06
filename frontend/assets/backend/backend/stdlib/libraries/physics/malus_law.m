function I = malus_law(I0, theta)
    % MALUS_LAW Intensity of light passing through a polarizer
    % I = I0 * cos(theta)^2
    if nargin < 1, I0 = []; end
    if nargin < 2, theta = []; end
    I = I0 * cos(theta)^2;
end
