function Cxy = coherence_signal(x, y)
    % COHERENCE_SIGNAL Magnitude-squared coherence
    if nargin < 1, x = []; end
    if nargin < 2, y = []; end
    Sxy = cross_spectrum(x, y);
    Sxx = cross_spectrum(x, x);
    Syy = cross_spectrum(y, y);
    Cxy = (abs(Sxy).^2) ./ (Sxx .* Syy);
end
