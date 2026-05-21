function Cxy = coherence_signal(x, y)
    % COHERENCE_SIGNAL Magnitude-squared coherence
    Sxy = cross_spectrum(x, y);
    Sxx = cross_spectrum(x, x);
    Syy = cross_spectrum(y, y);
    Cxy = (abs(Sxy).^2) ./ (Sxx .* Syy);
end
