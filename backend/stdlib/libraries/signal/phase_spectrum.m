function ph = phase_spectrum(x)
    % PHASE_SPECTRUM Phase of the signal spectrum
    if nargin < 1, x = []; end
    X = fft(x);
    ph = angle(X);
end
