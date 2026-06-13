function mag = magnitude_spectrum(x)
    % MAGNITUDE_SPECTRUM Magnitude of the signal spectrum
    if nargin < 1, x = []; end
    X = fft(x);
    mag = abs(X);
end
