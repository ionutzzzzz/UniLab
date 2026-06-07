function Sxy = cross_spectrum(x, y)
    % CROSS_SPECTRUM FFT(x) * conj(FFT(y))
    X = fft(x);
    Y = fft(y);
    Sxy = X .* conj(Y);
end
