function alpha = gravitational_lensing_angle(M, b, G, c)
    % GRAVITATIONAL_LENSING_ANGLE Deflection angle of light by a massive object
    % alpha = gravitational_lensing_angle(M, b, G, c)
    % M: mass of the lens, b: impact parameter
    
    if nargin < 1, M = []; end
    if nargin < 2, b = []; end
    if nargin < 3, G = 6.67430e-11; end
    if nargin < 4, c = 299792458; end
    
    alpha = (4 * G * M) / (b * c^2);
end
