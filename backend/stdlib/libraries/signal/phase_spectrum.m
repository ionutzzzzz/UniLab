function ph = phase_spectrum(x)
    % PHASE_SPECTRUM Phase of the signal spectrum
    X = fft(x);
    ph = angle(X);
end
