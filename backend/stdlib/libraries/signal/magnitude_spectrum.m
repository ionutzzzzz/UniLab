function mag = magnitude_spectrum(x)
    % MAGNITUDE_SPECTRUM Magnitude of the signal spectrum
    X = fft(x);
    mag = abs(X);
end
